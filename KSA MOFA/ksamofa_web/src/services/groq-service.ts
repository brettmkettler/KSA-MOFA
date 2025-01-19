import jsonlines from 'jsonlines';

interface Message {
  role: 'system' | 'user' | 'assistant';
  content: string;
}

interface ChatResponse {
  choices: {
    message: {
      content: string;
    };
  }[];
}

interface EmbeddingResponse {
  data: {
    embedding: number[];
  }[];
}

interface DocumentMetadata {
  heading: string;
  source: string;
  url?: string;
}

interface DocumentChunk {
  chunk: string;
  metadata: DocumentMetadata;
}

interface ProcessedDocument {
  content: string;
  metadata: DocumentMetadata;
  embedding?: number[];
}

interface UserProfile {
  name: string;
  citizenship: string;
  age: number;
}

const GROQ_API_KEY = "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";
const BASE_URL = "https://api.openai.com/v1";

const getSystemPrompt = (userProfile: UserProfile) => `
You are a helpful assistant for the KSA MOFA (Ministry of Foreign Affairs).
You are currently assisting ${userProfile.name}, a ${userProfile.age}-year-old citizen of ${userProfile.citizenship}.
Provide clear, direct answers about MOFA services and information, tailoring the information based on the user's citizenship and age.
For citizens of Saudi Arabia, provide more detailed internal process information.
For citizens of other countries, focus on visa requirements, foreign relations, and consular services.

IMPORTANT FORMATTING INSTRUCTIONS:
1. Always structure your responses in clear sections using markdown
2. Include relevant links from the provided context when available
3. Format links as [Link Text](URL)
4. Use tables for comparing multiple items or services
5. Use bullet points for lists of requirements or steps
6. Always include relevant service links when available

FORMAT YOUR RESPONSES IN MARKDOWN:
- Use headers (##) for main sections
- Use bullet points (*) for lists
- Use bold (**) for emphasis
- Use code blocks (\`\`) for technical terms or specific requirements
- Use tables for structured data
- Use > for important notes or quotes
- Include line breaks between sections for readability

When providing information about services or procedures:
1. Start with a clear overview
2. List any requirements or prerequisites
3. Provide step-by-step instructions if applicable
4. Include relevant links to official pages
5. Add any special notes for the user's specific citizenship

Example format:
## Service Overview
* Point 1
* Point 2

**Important note:** Key information

> Special note for ${userProfile.citizenship} citizens

\`Technical requirement\`

[Official Documentation](URL)
`;

// Cache for document embeddings
let documentEmbeddings: Map<string, ProcessedDocument> = new Map();

export async function generateEmbedding(text: string): Promise<number[]> {
  const endpoint = `${BASE_URL}/embeddings`;
  
  try {
    const response = await fetch(endpoint, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${GROQ_API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'text-embedding-ada-002',
        input: text,
      }),
    });

    if (!response.ok) {
      throw new Error(`API request failed: ${response.statusText}`);
    }

    const data: EmbeddingResponse = await response.json();
    return data.data[0].embedding;
  } catch (error) {
    console.error('Error generating embedding:', error);
    throw error;
  }
}

export async function processDocument(docData: DocumentChunk): Promise<ProcessedDocument> {
  try {
    const content = docData.chunk;
    const metadata = docData.metadata;
    
    const embedding = await generateEmbedding(content);
    const processedDoc: ProcessedDocument = {
      content,
      metadata,
      embedding
    };
    
    const key = `${metadata.source}-${metadata.heading}`;
    documentEmbeddings.set(key, processedDoc);
    return processedDoc;
  } catch (error) {
    console.error(`Error processing document ${docData.metadata.heading}:`, error);
    throw error;
  }
}

export async function loadAndProcessDocuments(): Promise<void> {
  try {
    console.log('Starting document loading process...');
    const response = await fetch('/src/docs/Chunked_Markdown_Data_Cleaned.jsonl');
    if (!response.ok) {
      throw new Error(`Failed to fetch JSONL file: ${response.statusText}`);
    }
    
    const text = await response.text();
    const lines = text.split('\n').filter(line => line.trim());
    console.log(`Found ${lines.length} documents to process`);
    
    let processedCount = 0;
    for (const line of lines) {
      try {
        const docData = JSON.parse(line) as DocumentChunk;
        await processDocument(docData);
        processedCount++;
        
        if (processedCount % 10 === 0) {
          console.log(`Processed ${processedCount} documents...`);
        }
      } catch (error) {
        console.error('Error processing JSONL line:', error);
      }
    }
    
    console.log(`Successfully processed ${documentEmbeddings.size} documents`);
  } catch (error) {
    console.error('Error loading documents:', error);
    throw error;
  }
}

function cosineSimilarity(a: number[], b: number[]): number {
  let dotProduct = 0;
  let normA = 0;
  let normB = 0;
  
  for (let i = 0; i < a.length; i++) {
    dotProduct += a[i] * b[i];
    normA += a[i] * a[i];
    normB += b[i] * b[i];
  }
  
  return dotProduct / (Math.sqrt(normA) * Math.sqrt(normB));
}

async function findRelevantDocuments(query: string, topK: number = 5): Promise<ProcessedDocument[]> {
  try {
    console.log(`Finding relevant documents for query: ${query}`);
    console.log(`Current document cache size: ${documentEmbeddings.size}`);
    
    const queryEmbedding = await generateEmbedding(query);
    const documents = Array.from(documentEmbeddings.values());
    
    const documentsWithScores = documents
      .map(doc => ({
        doc,
        score: doc.embedding ? cosineSimilarity(queryEmbedding, doc.embedding) : -1,
      }))
      .filter(item => item.score > 0.7) // Only include highly relevant documents
      .sort((a, b) => b.score - a.score)
      .slice(0, topK);
    
    console.log(`Found ${documentsWithScores.length} relevant documents`);
    return documentsWithScores.map(item => item.doc);
  } catch (error) {
    console.error('Error finding relevant documents:', error);
    throw error;
  }
}

function formatContextFromDocs(docs: ProcessedDocument[]): string {
  return docs.map(doc => {
    let formattedContent = doc.content;
    const metadata = doc.metadata;
    
    // Add heading if available
    if (metadata.heading) {
      formattedContent = `# ${metadata.heading}\n${formattedContent}`;
    }
    
    // Add source if available
    if (metadata.source) {
      formattedContent += `\nSource: ${metadata.source}`;
    }
    
    // Add URL if available
    if (metadata.url) {
      formattedContent += `\nReference: [${metadata.heading || 'Link'}](${metadata.url})`;
    }
    
    return formattedContent;
  }).join('\n\n---\n\n');
}

export async function generateResponse(
  message: string,
  context?: string,
  previousMessages: Message[] = [],
  userProfile: UserProfile
): Promise<string> {
  try {
    console.log('Generating response for message:', message);
    
    // Find relevant documents based on the query
    const relevantDocs = await findRelevantDocuments(message);
    const contextFromDocs = formatContextFromDocs(relevantDocs);

    const endpoint = `${BASE_URL}/chat/completions`;
    const messages: Message[] = [
      { role: 'system', content: getSystemPrompt(userProfile) },
    ];

    if (contextFromDocs) {
      messages.push({
        role: 'system',
        content: `Use this information to inform your response. Include relevant URLs as markdown links where appropriate: ${contextFromDocs}`,
      });
    }

    // Add conversation history
    const recentMessages = previousMessages.slice(-10);
    messages.push(...recentMessages);

    // Add the current message
    messages.push({ role: 'user', content: message });

    console.log('Sending request to OpenAI...');
    const response = await fetch(endpoint, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${GROQ_API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'gpt-4',
        messages,
        temperature: 0.2,
        max_tokens: 1000,
      }),
    });

    if (!response.ok) {
      throw new Error(`API request failed: ${response.statusText}`);
    }

    const data: ChatResponse = await response.json();
    console.log('Successfully generated response');
    return data.choices[0].message.content;
  } catch (error) {
    console.error('Error generating response:', error);
    throw error;
  }
}
