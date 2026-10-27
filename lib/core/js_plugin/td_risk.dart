/// TDLib 请求风险分级：决定 JS 插件调用前是否需要用户确认。
enum RiskLevel {
  /// 只读 / 无副作用，直接执行。
  safe,
  /// 有副作用（发消息、加好友等），需用户确认。
  confirm,
  /// 破坏性 / 账号级（删消息、登出、删号等），需用户明确确认。
  danger,
}

/// TDLib `@type` → 风险等级映射。
///
/// 默认视为 [RiskLevel.confirm]，避免「未知请求」裸奔。
class TdRisk {
  const TdRisk._();

  static const Map<String, RiskLevel> _rules = {
    // ---- safe：只读 ----
    'getMe': RiskLevel.safe,
    'getChats': RiskLevel.safe,
    'getChat': RiskLevel.safe,
    'getChatHistory': RiskLevel.safe,
    'getMessages': RiskLevel.safe,
    'getMessage': RiskLevel.safe,
    'getMessageThread': RiskLevel.safe,
    'searchPublicChat': RiskLevel.safe,
    'searchChatMessages': RiskLevel.safe,
    'searchChats': RiskLevel.safe,
    'getUser': RiskLevel.safe,
    'getBasicGroup': RiskLevel.safe,
    'getSupergroup': RiskLevel.safe,
    'getContacts': RiskLevel.safe,
    'getOptions': RiskLevel.safe,
    'getRecentStickers': RiskLevel.safe,
    'getInstalledStickerSets': RiskLevel.safe,
    'downloadFile': RiskLevel.safe,
    'readFilePart': RiskLevel.safe,

    // ---- confirm：有副作用 ----
    'sendMessage': RiskLevel.confirm,
    'sendBotStartMessage': RiskLevel.confirm,
    'sendInlineQueryResultMessage': RiskLevel.confirm,
    'createPrivateChat': RiskLevel.confirm,
    'createBasicGroupChat': RiskLevel.confirm,
    'createSupergroupChat': RiskLevel.confirm,
    'joinChat': RiskLevel.confirm,
    'leaveChat': RiskLevel.confirm,
    'addContact': RiskLevel.confirm,
    'removeContact': RiskLevel.confirm,
    'blockUser': RiskLevel.confirm,
    'unblockUser': RiskLevel.confirm,
    'toggleChatIsMarkedAsUnread': RiskLevel.confirm,
    'toggleMessageIsPinned': RiskLevel.confirm,
    'viewMessages': RiskLevel.confirm,
    'openChat': RiskLevel.confirm,
    'closeChat': RiskLevel.confirm,
    'addProxy': RiskLevel.confirm,
    'removeProxy': RiskLevel.confirm,
    'enableProxy': RiskLevel.confirm,
    'disableProxy': RiskLevel.confirm,
    'setProxy': RiskLevel.confirm,
    'uploadFile': RiskLevel.confirm,
    'setOption': RiskLevel.confirm,
    'setChatTitle': RiskLevel.confirm,
    'setChatDescription': RiskLevel.confirm,
    'setProfilePhoto': RiskLevel.confirm,
    'setName': RiskLevel.confirm,
    'setBio': RiskLevel.confirm,
    'editMessageText': RiskLevel.confirm,
    'editMessageCaption': RiskLevel.confirm,
    'forwardMessages': RiskLevel.confirm,

    // ---- danger：破坏性 / 账号级 ----
    'deleteMessages': RiskLevel.danger,
    'deleteChatHistory': RiskLevel.danger,
    'removeChatMember': RiskLevel.danger,
    'logout': RiskLevel.danger,
    'deleteAccount': RiskLevel.danger,
    'terminateAllOtherSessions': RiskLevel.danger,
    'terminateSession': RiskLevel.danger,
    'setAuthenticationPhoneNumber': RiskLevel.danger,
    'checkAuthenticationCode': RiskLevel.danger,
    'checkAuthenticationPassword': RiskLevel.danger,
    'resendAuthenticationCode': RiskLevel.danger,
    'resetPassword': RiskLevel.danger,
  };

  static RiskLevel levelOf(String type) => _rules[type] ?? RiskLevel.confirm;

  /// 给用户看的人类可读描述。
  static String describe(String type, Map<String, dynamic> query) {
    switch (type) {
      case 'sendMessage':
        return '向聊天 ${query['chat_id']} 发送消息';
      case 'editMessageText':
        return '编辑聊天 ${query['chat_id']} 的消息';
      case 'forwardMessages':
        return '转发消息到聊天 ${query['chat_id']}';
      case 'deleteMessages':
        return '删除聊天 ${query['chat_id']} 中的消息';
      case 'deleteChatHistory':
        return '清空聊天 ${query['chat_id']} 的历史';
      case 'leaveChat':
        return '退出聊天 ${query['chat_id']}';
      case 'joinChat':
        return '加入聊天 ${query['chat_id']}';
      case 'blockUser':
        return '拉黑用户 ${query['user_id']}';
      case 'unblockUser':
        return '取消拉黑用户 ${query['user_id']}';
      case 'removeContact':
        return '删除联系人 ${query['user_id']}';
      case 'addProxy':
      case 'setProxy':
        return '设置代理';
      case 'removeProxy':
        return '移除代理';
      case 'logout':
        return '登出当前账号';
      case 'deleteAccount':
        return '删除账号（不可恢复）';
      case 'terminateAllOtherSessions':
        return '终止其他所有登录会话';
      case 'setAuthenticationPhoneNumber':
        return '发起登录（更换手机号）';
      default:
        return '执行 TDLib 请求：$type';
    }
  }
}
