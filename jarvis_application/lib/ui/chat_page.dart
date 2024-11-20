import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'package:jarvis_application/models/ai_chat_metadata.dart';
import 'package:jarvis_application/models/request_ai_chat.dart';
import 'package:jarvis_application/widgets/chat/greeting_text.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';

import '../models/assistant.dart';
import '../models/assistant_dto.dart';
import '../models/chat_message.dart';
import '../widgets/chat/action_row.dart';
import '../widgets/chat/ai_model_dropdown.dart';
import '../widgets/chat/conversation_history_dialog.dart';
import '../widgets/chat/image_picker_helper.dart';
import '../widgets/chat/logo_widget.dart';
import '../widgets/chat/upload_dialog.dart';
import '../models/assistant.dart';
import 'dart:convert';

class ChatPage extends StatefulWidget {
  static const String routeName = '/chat';

  const ChatPage({Key? key}) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  final TextEditingController messageController = TextEditingController();
  final ScreenshotController screenshotController = ScreenshotController();
  final ScrollController _scrollController = ScrollController();

  final FocusNode messageFocusNode = FocusNode();
  final metadata = AiChatMetadata.empty();
  late int remainUsage ;

  late ChatMessage currentMessageUser;
  late ChatMessage currentMessageAI;

  late RequestAiChat requestAiChat;
  bool isTyping = false;


  String conversationId = '';
  final List<Assistant> assistants = [
    Assistant(
      dto: AssistantDto(id: Id.GPT_4_O, model: Model.DIFY),
      imagePath: 'assets/images/gpt-4.jpg',
    ),
    Assistant(
      dto: AssistantDto(id: Id.CLAUDE_3_HAIKU_20240307, model: Model.DIFY),
      imagePath: 'assets/images/claude-3-sonnet.png',
    ),
  ];

  List<Map<String, dynamic>> items = [
    {
      'title': 'Hi',
      'id': 'f32a6751-9200-4357-9281-d22e5785434c',
      'createdAt': 1730480205,
    },
    {
      'title': 'Hello',
      'id': 'd34b6751-9234-4567-9281-df43c5e5486c',
      'createdAt': 1730470205,
    },
  ];
  final List<ChatMessage> messages = [];
  String? cursor = 'f32a6751-9200-4357-9281-d22e5785434c'; // Cursor for pagination




  Assistant? selectedAssistant;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    selectedAssistant = assistants.isNotEmpty ? assistants.first : null;
    // initial Message  = empty
    currentMessageUser = ChatMessage.empty();
    currentMessageAI = ChatMessage.empty();
    remainUsage= 29;
    requestAiChat = RequestAiChat(
      assistant: selectedAssistant!.dto,
      content: '',
      metadata: metadata,
    );


  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    messageController.dispose();
    messageFocusNode.dispose(); // Dispose the focus node
    super.dispose();
  }

  // Future<void> _sendMessage(String content, Assistant currAssistant) async {
  //   messages.add(ChatMessage(
  //     role: 'user',
  //     content: content,));
  //
  //   // send request to API
  //     currentMessage.setValues(
  //       newRole: 'user',
  //       newContent: content,
  //       newAssistant: currAssistant.dto);
  //   requestAiChat.addMessage(currentMessage);
  //
  //   print("requestttttttt111111111111111: ${jsonEncode(requestAiChat.toJson())}");
  //
  //   // get response from API
  //   currentMessage.setValues(
  //     newRole: 'model',
  //     newContent: 'I am an AI assistant. How can I help you?',
  //     newAssistant: currAssistant.dto);
  //   requestAiChat.addConversationID("1234567890");
  //   requestAiChat.addMessage(currentMessage);
  //
  //
  //   print("requestttttttt2222222222222222222222: ${jsonEncode(requestAiChat.toJson())}");
  //
  //
  //
  //   String responseJson = '''
  //   {
  //     "conversationId": "f32a6751-9200-4357-9281-d22e5785434c",
  //     "message": "Hello! It's nice to meet you. I'm Jarvis, an AI assistant created by Anthropic. I'm here to help with any questions or tasks you might have. How can I assist you today?",
  //     "remainingUsage": 49
  //   }
  //   ''';
  //   Map<String, dynamic> responseAIChat = jsonDecode(responseJson);
  //
  //   // Lấy giá trị từ Map và gán vào các biến
  //   String conversationId = responseAIChat['conversationId'];
  //   String message = responseAIChat['message'];
  //   int remainingUsage = responseAIChat['remainingUsage'];
  //
  //
  // }

  Future<void> _sendMessage(String content, Assistant currAssistant) async {
    // Add message to the local list
    messages.add(ChatMessage(
      role: 'user',
      content: content,
    ));
    setState(() {
      isTyping = true;
    });



    print("Request Body Before Sending: ${jsonEncode(requestAiChat.toJson())}");

    // Setup headers and URL
    var headers = {
      'x-jarvis-guid': '',
      'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6ImYzYTg4YjNhLWQxZDUtNGM0ZC04OWNlLTcxOTNjY2I3ZWQyYyIsImVtYWlsIjoicXVhbmd0aGllbjEyQGdtYWlsLmNvbSIsImlhdCI6MTczMjExNzg5MSwiZXhwIjoxNzYzNjUzODkxfQ.fwoNzY-jOZCtaypq-yB6-suwrJ7UO7ms5iFUNWpDyf8',
      'Content-Type': 'application/json',
    };
    var url = Uri.parse('https://api.dev.jarvis.cx/api/v1/ai-chat');

    // Send request to the API
    try {
      var request = http.Request('POST', url);

      if(metadata.conversation.id == ""){
        requestAiChat.setContent(content);
        requestAiChat.setAssistant(currAssistant.dto);
        request.body = jsonEncode(requestAiChat.toJsonFirstTime());
      }
      else {
        currentMessageUser.setValues(
            newRole: 'user',
            newContent: content,
            newAssistant: currAssistant.dto);

        requestAiChat.setContent(content);
        requestAiChat.setAssistant(currAssistant.dto);
        request.body = jsonEncode(requestAiChat.toJson());
      }

      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();

      // Read response
      if (response.statusCode == 200) {
        String responseJson = await response.stream.bytesToString();
        Map<String, dynamic> responseAIChat = jsonDecode(responseJson);

        // Extract values from the response
        String conversationId = responseAIChat['conversationId'];
        String messageAI = responseAIChat['message'];
        int remainingUsage = responseAIChat['remainingUsage'];
        print("requestttttttt111111111111111: ${jsonEncode(requestAiChat.toJson())}");
        print("Response JSON: $responseJson");
        print("Conversation ID: $conversationId");
        print("Message: $messageAI");
        print("Remaining Usage: $remainingUsage");

        messages.add(ChatMessage(
          role: 'model',
          content: messageAI,

        ));

        setState(() {
          remainUsage = remainingUsage;
        }); // Đảm bảo UI được cập nhật
        _scrollToBottom();

        currentMessageAI.setValues(
            newRole: 'model',
            newContent: messageAI,
            newAssistant: currAssistant.dto);
        requestAiChat.setConversationID(conversationId);
        requestAiChat.addMessage(currentMessageUser);
        requestAiChat.addMessage(currentMessageAI);


        // Optionally update local state or UI
      } else {
        String errorMessage =
            "Request failed with status: ${response.statusCode}\nReason: ${response.reasonPhrase}";
        _showErrorDialog(context, "Error", errorMessage);
      }
    } catch (e) {
      _showErrorDialog(context, "Error", "An error occurred: $e");    } finally{
      setState(() {
        isTyping = false;
      });
    }
  }


  void _showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }




  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }



  Widget _buildChatInput() {
    return GestureDetector(
        onTap: () {
      FocusScope.of(context).unfocus(); // Dismiss keyboard when tapping outside the input
                                        // but it doesn't work =((
    },
    child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFEEEEEE),
            borderRadius: BorderRadius.circular(20.0),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
                onPressed: () {
                  ImagePickerHelper.showImagePickerOptions(
                    context,
                    screenshotController: screenshotController,
                  );
                },
              ),
              Expanded(
                child: TextField(
                  focusNode: messageFocusNode, // Attach the focus node
                  controller: messageController,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8.0),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send, color: Colors.blue),
                onPressed: () {
                  final text = messageController.text.trim();
                  if (text.isNotEmpty) {
                    _sendMessage(text, selectedAssistant!);
                    messageController.clear();
                    FocusScope.of(context).unfocus(); // Dismiss keyboard after sending
                  }
                },
              ),
            ],
          ),
        ),
    ),
    );
  }


  void _handleAction(String action, BuildContext context) {
    switch (action) {
      case 'add_comment':
        print("Add comment pressed");
        break;
      case 'upload_pdf':
        _showUploadDialog(context);
        break;
      case 'view_book':
        print("View book pressed");
        break;
      case 'view_history':
        _showConversationHistoryDialog(context);
        break;
      default:
        print("Unknown action: $action");
    }
  }

  void _showUploadDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return UploadDialog(
          onFilePicked: (file) {
            if (file != null) {
              print('Selected file: ${file.path}');

              // Xử lý file tải lên
            }
          },
        );
      },
    );
  }

  void _showConversationHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return ConversationHistoryDialog(
          initialItems: items, // Truyền danh sách items
          cursor: cursor, // Truyền cursor cho dialog
          onItemsUpdated: (updatedItems) {
            setState(() {
              items = updatedItems; // Cập nhật danh sách khi xóa
            });
          },
        );
      },
    );
  }




  @override
  Widget build(BuildContext context) {
    return Screenshot(
      controller: screenshotController,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Chat',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/publishing-platforms');
              },
              child: const Text(
                'Publish',
                style: TextStyle(color: Colors.blue, fontSize: 16),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 10),
              LogoWidget(),
              const SizedBox(height: 10),
              GreetingText(),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length +(isTyping ? 1:0),
                  itemBuilder: (context, index) {

                    if (index == messages.length && isTyping) {
                      // Hiển thị hiệu ứng "jumping dots" khi đang chờ phản hồi
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SpinKitThreeBounce(
                            color: Colors.grey,
                            size: 20.0,
                          ),
                        ),
                      );
                    }

                    final message = messages[index];
                    return Align(
                      alignment: message.role == 'user'
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: message.role == 'user'
                              ? Colors.blue[100]
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(message.content),
                      ),
                    );
                  },
                ),
              ),
              ActionRow(
                assistants: assistants,
                selectedAssistant: selectedAssistant,
                onAssistantSelected: (assistant){
                  setState(() {
                    selectedAssistant = assistant;
                  });
                },
                onActionSelected: (action) {
                  _handleAction(action, context);
                },
                remainUsage: remainUsage,
              ),
              _buildChatInput(),
            ],
          ),
        ),
      ),
    );
  }
}




