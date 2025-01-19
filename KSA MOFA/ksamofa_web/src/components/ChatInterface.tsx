import React, { useState, useEffect } from 'react';
import {
  Box,
  Flex,
  Input,
  IconButton,
  VStack,
  Text,
  Image,
  Container,
  useToast,
  FormControl,
  FormLabel,
  Select,
  NumberInput,
  NumberInputField,
  NumberInputStepper,
  NumberIncrementStepper,
  NumberDecrementStepper,
  Button,
} from '@chakra-ui/react';
import { IoSend } from 'react-icons/io5';
import { generateResponse, loadAndProcessDocuments } from '../services/groq-service';
import ReactMarkdown from 'react-markdown';

interface UserProfile {
  name: string;
  citizenship: string;
  age: number;
}

interface Message {
  id: string;
  text: string;
  sender: 'user' | 'ai';
  timestamp: Date;
}

const countries = [
  'United States',
  'United Kingdom',
  'Canada',
  'Australia',
  'Saudi Arabia',
  'UAE',
  'India',
  'Pakistan',
  'China',
  'Japan',
  // Add more countries as needed
];

const MarkdownMessage: React.FC<{ content: string }> = ({ content }) => {
  return (
    <Box
      className="markdown-content"
      sx={{
        'h1, h2, h3, h4, h5, h6': {
          fontWeight: 'bold',
          marginBottom: '0.5em',
          marginTop: '0.5em',
        },
        'h1': { fontSize: '1.5em' },
        'h2': { fontSize: '1.3em' },
        'h3': { fontSize: '1.1em' },
        'p': {
          marginBottom: '0.5em',
        },
        'ul, ol': {
          paddingLeft: '1.5em',
          marginBottom: '0.5em',
        },
        'li': {
          marginBottom: '0.25em',
        },
        'code': {
          bg: 'gray.100',
          padding: '0.2em 0.4em',
          borderRadius: '0.3em',
          fontSize: '0.9em',
        },
        'pre': {
          bg: 'gray.100',
          padding: '1em',
          borderRadius: '0.5em',
          overflowX: 'auto',
          marginBottom: '0.5em',
        },
        'blockquote': {
          borderLeft: '4px solid',
          borderColor: 'blue.200',
          paddingLeft: '1em',
          marginLeft: '0',
          marginBottom: '0.5em',
          color: 'gray.600',
        },
        'table': {
          width: '100%',
          marginBottom: '1em',
          borderCollapse: 'collapse',
        },
        'th, td': {
          border: '1px solid',
          borderColor: 'gray.200',
          padding: '0.5em',
        },
        'th': {
          bg: 'gray.50',
          fontWeight: 'bold',
        },
        'a': {
          color: 'blue.500',
          textDecoration: 'underline',
        },
      }}
    >
      <ReactMarkdown>{content}</ReactMarkdown>
    </Box>
  );
};

export const ChatInterface: React.FC = () => {
  const [messages, setMessages] = useState<Message[]>([]);
  const [inputMessage, setInputMessage] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [isInitializing, setIsInitializing] = useState(true);
  const [showProfile, setShowProfile] = useState(true);
  const [userProfile, setUserProfile] = useState<UserProfile>({
    name: '',
    citizenship: '',
    age: 25,
  });
  const toast = useToast();

  useEffect(() => {
    const initializeDocuments = async () => {
      try {
        await loadAndProcessDocuments();
        setIsInitializing(false);
      } catch (error) {
        console.error('Error initializing documents:', error);
        toast({
          title: 'Initialization Error',
          description: 'Failed to load document data. Some features may be limited.',
          status: 'error',
          duration: 5000,
          isClosable: true,
        });
        setIsInitializing(false);
      }
    };

    initializeDocuments();
  }, [toast]);

  const handleProfileSubmit = () => {
    if (!userProfile.name || !userProfile.citizenship) {
      toast({
        title: 'Profile Incomplete',
        description: 'Please fill in your name and citizenship.',
        status: 'warning',
        duration: 3000,
        isClosable: true,
      });
      return;
    }
    setShowProfile(false);
  };

  const handleSendMessage = async () => {
    if (!inputMessage.trim() || isLoading) return;

    const newMessage: Message = {
      id: Date.now().toString(),
      text: inputMessage,
      sender: 'user',
      timestamp: new Date(),
    };

    setMessages((prev) => [...prev, newMessage]);
    setInputMessage('');
    setIsLoading(true);

    try {
      const previousMessages = messages.map(msg => ({
        role: msg.sender === 'user' ? 'user' : 'assistant' as const,
        content: msg.text
      }));

      const response = await generateResponse(
        inputMessage,
        undefined,
        previousMessages,
        userProfile
      );

      const aiResponse: Message = {
        id: (Date.now() + 1).toString(),
        text: response,
        sender: 'ai',
        timestamp: new Date(),
      };

      setMessages((prev) => [...prev, aiResponse]);
    } catch (error) {
      console.error('Error getting AI response:', error);
      toast({
        title: 'Error',
        description: 'Failed to get a response. Please try again.',
        status: 'error',
        duration: 5000,
        isClosable: true,
      });
    } finally {
      setIsLoading(false);
    }
  };

  if (showProfile) {
    return (
      <Box minH="100vh" bg="gray.50">
        <Container maxW="container.lg" p={0}>
          {/* Header with MOFA Logo */}
          <Flex
            bg="white"
            p={4}
            shadow="sm"
            alignItems="center"
            justifyContent="center"
            borderBottom="1px"
            borderColor="gray.200"
          >
            <Image
              src="/mofa_logo_h.svg"
              alt="MOFA Logo"
              h="40px"
              objectFit="contain"
            />
          </Flex>

          {/* Profile Form */}
          <Box maxW="md" mx="auto" mt={8} p={6} bg="white" borderRadius="lg" shadow="md">
            <VStack spacing={4}>
              <Text fontSize="xl" fontWeight="bold">Welcome to MOFA Chat</Text>
              <Text color="gray.600">Please provide your information to continue</Text>
              
              <FormControl isRequired>
                <FormLabel>Name</FormLabel>
                <Input
                  value={userProfile.name}
                  onChange={(e) => setUserProfile(prev => ({ ...prev, name: e.target.value }))}
                  placeholder="Enter your full name"
                />
              </FormControl>

              <FormControl isRequired>
                <FormLabel>Citizenship</FormLabel>
                <Select
                  value={userProfile.citizenship}
                  onChange={(e) => setUserProfile(prev => ({ ...prev, citizenship: e.target.value }))}
                  placeholder="Select your citizenship"
                >
                  {countries.map(country => (
                    <option key={country} value={country}>{country}</option>
                  ))}
                </Select>
              </FormControl>

              <FormControl>
                <FormLabel>Age</FormLabel>
                <NumberInput
                  value={userProfile.age}
                  onChange={(_, value) => setUserProfile(prev => ({ ...prev, age: value }))}
                  min={18}
                  max={100}
                >
                  <NumberInputField />
                  <NumberInputStepper>
                    <NumberIncrementStepper />
                    <NumberDecrementStepper />
                  </NumberInputStepper>
                </NumberInput>
              </FormControl>

              <Button
                colorScheme="blue"
                width="full"
                mt={4}
                onClick={handleProfileSubmit}
              >
                Start Chat
              </Button>
            </VStack>
          </Box>
        </Container>
      </Box>
    );
  }

  return (
    <Box minH="100vh" bg="gray.50">
      <Container maxW="container.lg" p={0}>
        {/* Header with MOFA Logo and User Info */}
        <Flex
          bg="white"
          p={4}
          shadow="sm"
          alignItems="center"
          justifyContent="space-between"
          borderBottom="1px"
          borderColor="gray.200"
        >
          <Image
            src="/mofa_logo_h.svg"
            alt="MOFA Logo"
            h="40px"
            objectFit="contain"
          />
          <Flex alignItems="center" gap={4}>
            <Text fontSize="sm" color="gray.600">
              Welcome, <Text as="span" fontWeight="bold">{userProfile.name}</Text>
            </Text>
            <Text fontSize="sm" color="gray.600">
              Citizenship: <Text as="span" fontWeight="bold">{userProfile.citizenship}</Text>
            </Text>
          </Flex>
        </Flex>

        {/* Chat Container */}
        <Flex direction="column" h="calc(100vh - 72px)" maxW="container.md" mx="auto" p={4}>
          {isInitializing ? (
            <Flex justify="center" align="center" flex={1}>
              <Text color="gray.500">Loading document data...</Text>
            </Flex>
          ) : (
            <>
              <VStack
                flex={1}
                overflowY="auto"
                spacing={4}
                mb={4}
                align="stretch"
                css={{
                  '&::-webkit-scrollbar': {
                    width: '4px',
                  },
                  '&::-webkit-scrollbar-track': {
                    width: '6px',
                  },
                  '&::-webkit-scrollbar-thumb': {
                    background: '#E2E8F0',
                    borderRadius: '24px',
                  },
                }}
              >
                {messages.map((message) => (
                  <Box
                    key={message.id}
                    alignSelf={message.sender === 'user' ? 'flex-end' : 'flex-start'}
                    bg={message.sender === 'user' ? 'blue.500' : 'white'}
                    color={message.sender === 'user' ? 'white' : 'black'}
                    px={4}
                    py={2}
                    borderRadius="lg"
                    maxW="70%"
                    shadow="md"
                  >
                    {message.sender === 'user' ? (
                      <Text>{message.text}</Text>
                    ) : (
                      <MarkdownMessage content={message.text} />
                    )}
                    <Text fontSize="xs" opacity={0.7} mt={1}>
                      {message.timestamp.toLocaleTimeString()}
                    </Text>
                  </Box>
                ))}
              </VStack>

              <Flex>
                <Input
                  value={inputMessage}
                  onChange={(e) => setInputMessage(e.target.value)}
                  placeholder="Type your message..."
                  mr={2}
                  bg="white"
                  border="1px solid"
                  borderColor="gray.200"
                  _hover={{ borderColor: 'gray.300' }}
                  onKeyPress={(e) => {
                    if (e.key === 'Enter') {
                      handleSendMessage();
                    }
                  }}
                  isDisabled={isLoading}
                />
                <IconButton
                  aria-label="Send message"
                  icon={<IoSend />}
                  onClick={handleSendMessage}
                  colorScheme="blue"
                  isLoading={isLoading}
                />
              </Flex>
            </>
          )}
        </Flex>
      </Container>
    </Box>
  );
};
