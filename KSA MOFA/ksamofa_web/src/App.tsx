import { ChakraProvider } from '@chakra-ui/react'
import { ChatInterface } from './components/ChatInterface'
import theme from './theme'

export default function App() {
  return (
    <ChakraProvider theme={theme}>
      <ChatInterface />
    </ChakraProvider>
  )
}
