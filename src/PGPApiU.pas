//
//  PAXON Packet Radio Terminal
//
//  Copyright 1996-2026 Ulf Haueisen <ulf@paxon.app>, Frankfurt, Germany
//
//  This file is part of PAXON.
//
//  SPDX-License-Identifier: MIT
//  PAXON is licensed under the MIT License; see LICENSE.md in the project root.
//
//  The declarations of this unit follow the C headers of the PGPsdk 1.x
//  (Pretty Good Privacy, Inc. / Network Associates).
//


unit PGPApiU;


interface


uses
  Windows, SysUtils;


type
  EPGPApi = class (Exception);


type
  PGPUInt16 = Word;
  PGPBoolean = Byte;
  PGPUInt8 = Byte;
  PGPInt8 = Char;
  PGPInt16 = SmallInt;
  PGPUInt32 = Cardinal;
  PGPInt32 = Integer;
  PGPByte = PGPUINT8;
  PGPError = PGPINT32;
  PGPUserValue = Pointer;
  PGPSize = PGPUINT32;
  PGPFileOffset = Int64;
  PGPFlags = PGPUINT32;
  PGPTime = PGPUINT32;
  PGPTimeInterval = PGPUINT32;
  TIME_T = integer;
  PGPString = array[0..255] of char;
  PGPEnumType = integer;
  pPChar = ^PChar;
  PGPUInt64 = Int64;
  PGPInt64 = Int64;

const
  PGPTrue = 1;
  PGPFalse = 0;
  kPGPMemoryFlags_Clear = 1;

var
  kPGPsdkAPIVersion: PGPUINT32 = 0;


type
  PGPPublicKeyMessageFormat = PGPEnumType;

const
  kPGPPublicKeyMessageFormat_PGP = 1;
  kPGPPublicKeyMessageFormat_PKCS1 = 2;

type
  PGPCipherAlgorithm = PGPEnumType;

const
  kPGPCipherAlgorithm_None = 0;
  kPGPCipherAlgorithm_IDEA = 1;
  kPGPCipherAlgorithm_3DES = 2;
  kPGPCipherAlgorithm_CAST5 = 3;
  kPGPNumPossibleCipherAlgorithms = 3;

type
  PGPPublicKeyAlgorithm = PGPEnumType;

const
  kPGPPublicKeyAlgorithm_Invalid = $FFFFFFFF;
  kPGPPublicKeyAlgorithm_RSA = 1;
  kPGPPublicKeyAlgorithm_RSAEncryptOnly = 2;
  kPGPPublicKeyAlgorithm_RSASignOnly = 3;
  kPGPPublicKeyAlgorithm_ElGamal = $10;
  kPGPPublicKeyAlgorithm_DSA = $11;

  kPGPPublicKeyAlgorithm_First = kPGPPublicKeyAlgorithm_RSA;
  kPGPPublicKeyAlgorithm_Last = kPGPPublicKeyAlgorithm_DSA;

type
  PGPKeyOrdering = PGPEnumType;

const
  kPGPInvalidOrdering = 0;
  kPGPAnyOrdering = 1;
  kPGPUserIDOrdering = 2;
  kPGPReverseUserIDOrdering = 3;
  kPGPKeyIDOrdering = 4;
  kPGPReverseKeyIDOrdering = 5;
  kPGPValidityOrdering = 6;
  kPGPReverseValidityOrdering = 7;
  kPGPTrustOrdering = 8;
  kPGPReverseTrustOrdering = 9;
  kPGPEncryptKeySizeOrdering = 10;
  kPGPReverseEncryptKeySizeOrdering = 11;
  kPGPSigKeySizeOrdering = 12;
  kPGPReverseSigKeySizeOrdering = 13;
  kPGPCreationOrdering = 14;
  kPGPReverseCreationOrdering = 15;
  kPGPExpirationOrdering = 16;
  kPGPReverseExpirationOrdering = 17;

type
  PGPKeyPropName = PGPEnumType;

var
  kPGPKeyPropFingerprint: Integer = -1;
  kPGPKeyPropPreferredAlgorithms: Integer = -1;
  kPGPKeyPropThirdPartyRevocationKeyID: Integer = -1;

  kPGPKeyPropAlgID: Integer = -1;
  kPGPKeyPropBits: Integer = -1;
  kPGPKeyPropTrust: Integer = -1;
  kPGPKeyPropValidity: Integer = -1;
  kPGPKeyPropLockingAlgID: Integer = -1;
  kPGPKeyPropLockingBits: Integer = -1;
  kPGPKeyPropFlags: Integer = -1;

  kPGPKeyPropCreation: Integer = -1;
  kPGPKeyPropExpiration: Integer = -1;

  kPGPKeyPropIsSecret: Integer = -1;
  kPGPKeyPropIsAxiomatic: Integer = -1;
  kPGPKeyPropIsRevoked: Integer = -1;
  kPGPKeyPropIsDisabled: Integer = -1;
  kPGPKeyPropIsNotCorrupt: Integer = -1;
  kPGPKeyPropIsExpired: Integer = -1;
  kPGPKeyPropNeedsPassphrase: Integer = -1;
  kPGPKeyPropHasUnverifiedRevocation: Integer = -1;
  kPGPKeyPropCanEncrypt: Integer = -1;
  kPGPKeyPropCanDecrypt: Integer = -1;
  kPGPKeyPropCanSign: Integer = -1;
  kPGPKeyPropCanVerify: Integer = -1;
  kPGPKeyPropIsEncryptionKey: Integer = -1;
  kPGPKeyPropIsSigningKey: Integer = -1;
  kPGPKeyPropIsSecretShared: Integer = -1;
  kPGPKeyPropIsRevocable: Integer = -1;
  kPGPKeyPropHasThirdPartyRevocation: Integer = -1;

type
  PGPUserIDPropName = PGPEnumType;

var
  kPGPUserIDPropName: Integer = -1;
  kPGPUserIDPropAttributeData: Integer = -1;

  kPGPUserIDPropValidity: Integer = -1;
  kPGPUserIDPropConfidence: Integer = -1;
  kPGPUserIDPropAttributeType: Integer = -1;

  kPGPUserIDPropIsAttribute: Integer = -1;

type
  PGPSigPropName = PGPEnumType;

var

  kPGPSigPropKeyID: Integer = -1;
  kPGPSigPropX509Certificate: Integer = -1;

  kPGPSigPropAlgID: Integer = -1;
  kPGPSigPropTrustLevel: Integer = -1;
  kPGPSigPropTrustValue: Integer = -1;

  kPGPSigPropCreation: Integer = -1;
  kPGPSigPropExpiration: Integer = -1;

  kPGPSigPropIsRevoked: Integer = -1;
  kPGPSigPropIsNotCorrupt: Integer = -1;
  kPGPSigPropIsTried: Integer = -1;
  kPGPSigPropIsVerified: Integer = -1;
  kPGPSigPropIsMySig: Integer = -1;
  kPGPSigPropIsExportable: Integer = -1;
  kPGPSigPropHasUnverifiedRevocation: Integer = -1;
  kPGPSigPropIsExpired: Integer = -1;
  kPGPSigPropIsX509: Integer = -1;


type
  PGPKeyRingOpenFlags = PGPUInt32;

const
  kPGPKeyRingOpenFlags_Reserved = (1 shl 0);
  kPGPKeyRingOpenFlags_Mutable = (1 shl 1);
  kPGPKeyRingOpenFlags_Create = (1 shl 2);

  kPGPKeyRingOpenFlags_Private = (1 shl 8);
  kPGPKeyRingOpenFlags_Trusted = (1 shl 9);

type
  PGPMatchCriterion = PGPEnumType;

const
  kPGPMatchDefault = 1;
  kPGPMatchEqual = 1;
  kPGPMatchGreaterOrEqual = 2;
  kPGPMatchLessOrEqual = 3;
  kPGPMatchSubString = 4;

type
  PGPKeyIDStringType = PGPEnumType;

const
  kPGPKeyIDString_Abbreviated = 2;
  kPGPKeyIDString_Full = 3;
  kPGPMaxKeyIDStringSize = (127 + 1);

type
  PGPHashAlgorithm = PGPEnumType;

const
  kPGPHashAlgorithm_Invalid = 0;
  kPGPHashAlgorithm_MD5 = 1;
  kPGPHashAlgorithm_SHA = 2;
  kPGPHashAlgorithm_RIPEMD160 = 3;

type
  PGPValidity = PGPEnumType;

const
  kPGPKeyTrust_Mask = $7;
  kPGPKeyTrust_Undefined = $0;
  kPGPKeyTrust_Unknown = $1;
  kPGPKeyTrust_Never = $2;
  kPGPKeyTrust_Marginal = $5;
  kPGPKeyTrust_Complete = $6;
  kPGPKeyTrust_Ultimate = $7;

  kPGPNameTrust_Mask = $3;
  kPGPNameTrust_Unknown = $0;
  kPGPNameTrust_Untrusted = $1;
  kPGPNameTrust_Marginal = $2;
  kPGPNameTrust_Complete = $3;

  kPGPValidity_Unknown = kPGPNameTrust_Unknown;
  kPGPValidity_Invalid = kPGPNameTrust_Untrusted;
  kPGPValidity_Marginal = kPGPNameTrust_Marginal;
  kPGPValidity_Complete = kPGPNameTrust_Complete;
  kPGPValidity_UNTRUSTED = kPGPValidity_Invalid;

  kPGPMimeSeparatorSize = 81;

type
  PGPLineEndType = PGPEnumType;

const
  kPGPLineEnd_Default = 0;
  kPGPLineEnd_LF = 1;
  kPGPLineEnd_CR = 2;
  kPGPLineEnd_CRLF = kPGPLineEnd_LF or kPGPLineEnd_CR;

  kPGPLocalEncoding_None = $0;
  kPGPLocalEncoding_Force = $01;
  kPGPLocalEncoding_Auto = $02;
  kPGPLocalEncoding_NoMacBinCRCOkay = $04;

type
  PGPEventType = PGPEnumType;

const
  kPGPEvent_NullEvent = 0;
  kPGPEvent_InitialEvent = 1;
  kPGPEvent_FinalEvent = 2;
  kPGPEvent_ErrorEvent = 3;
  kPGPEvent_WarningEvent = 4;
  kPGPEvent_EntropyEvent = 5;
  kPGPEvent_PassphraseEvent = 6;
  kPGPEvent_InsertKeyEvent = 7;
  kPGPEvent_AnalyzeEvent = 8;
  kPGPEvent_RecipientsEvent = 9;
  kPGPEvent_KeyFoundEvent = 10;
  kPGPEvent_OutputEvent = 11;
  kPGPEvent_SignatureEvent = 12;
  kPGPEvent_BeginLexEvent = 13;
  kPGPEvent_EndLexEvent = 14;
  kPGPEvent_RecursionEvent = 15;
  kPGPEvent_DetachedSignatureEvent = 16;
  kPGPEvent_KeyGenEvent = 17;
  kPGPEvent_KeyServerEvent = 18;
  kPGPEvent_KeyServerSignEvent = 19;
  kPGPEvent_KeyServerTLSEvent = 20;
  kPGPEvent_KeyServerIdleEvent = 21;
  kPGPEvent_SocketsIdleEvent = 22;
  kPGPEvent_DecryptionEvent = 23;
  kPGPEvent_EncryptionEvent = 24;

type
  PGPAnalyzeType = PGPEnumType;

const
  kPGPAnalyze_Encrypted = 0;
  kPGPAnalyze_Signed = 1;
  kPGPAnalyze_DetachedSignature = 2;
  kPGPAnalyze_Key = 3;
  kPGPAnalyze_Unknown = 4;
  kPGPAnalyze_X509Certificate = 5;

type
  PGPFeatureSelector = PGPEnumType;

const
  kPGPFeatures_GeneralSelector = 1;
  kPGPFeatures_ImplementationSelector = 2;

  kPGPFeatureMask_CanEncrypt = $1;
  kPGPFeatureMask_CanDecrypt = $2;
  kPGPFeatureMask_CanSign = $4;
  kPGPFeatureMask_CanVerify = $8;
  kPGPFeatureMask_CanGenerate = $10;
  kPGPFeatureMask_RngHardware = $20;
  kPGPFeatureMask_IsDebugBuild = $1;
  kPGPFeatureMask_HasTimeout = $2;

type
  PGPsdkPrefSelector = PGPEnumType;

const
  kPGPsdkPref_DefaultKeyID = 3;
  kPGPsdkPref_PublicKeyring = 5;
  kPGPsdkPref_PrivateKeyring = 6;
  kPGPsdkPref_RandomSeedFile = 7;
  kPGPsdkPref_GroupsFile = 8;

type
  PGPKeyServerState = PGPEnumType;

const
  kPGPKeyServerState_Invalid = 0;
  kPGPKeyServerState_Opening = 1;
  kPGPKeyServerState_Querying = 2;
  kPGPKeyServerState_ReceivingResults = 3;
  kPGPKeyServerState_ProcessingResults = 4;
  kPGPKeyServerState_Uploading = 5;
  kPGPKeyServerState_Deleting = 6;
  kPGPKeyServerState_Disabling = 7;
  kPGPKeyServerState_Closing = 8;
  kPGPKeyServerState_TLSUnableToSecureConnection = 9;
  kPGPKeyServerState_TLSConnectionSecured = 10;

type
  PGPKeyServerKeySpace = PGPEnumType;

const
  kPGPKSKeySpaceDefault = 1;
  kPGPKSKeySpaceNormal = 2;
  kPGPKSKeySpacePending = 3;

type
  PGPKeyServerAccessType = PGPEnumType;

const
  kPGPKSAccess_Default = 1;
  kPGPKSAccess_Normal = 2;
  kPGPKSAccess_Administrator = 3;


  kPGPError_NoError = 0;

  kPGPError_BadParams = -12000;
  kPGPError_OutOfMemory = -11999;
  kPGPError_BufferTooSmall = -11998;

  kPGPError_FileNotFound = -11997;
  kPGPError_CantOpenFile = -11996;
  kPGPError_FilePermissions = -11995;
  kPGPError_FileLocked = -11994;
  kPGPError_DiskFull = -11960;
  kPGPError_DiskLocked = -11959;
  kPGPError_IllegalFileOp = -11992;
  kPGPError_FileOpFailed = -11991;
  kPGPError_ReadFailed = -11990;
  kPGPError_WriteFailed = -11989;
  kPGPError_EOF = -11988;

  kPGPError_UserAbort = -11987;
  kPGPError_UnknownRequest = -11986;
  kPGPError_LazyProgrammer = -11985;
  kPGPError_ItemNotFound = -11984;
  kPGPError_ItemAlreadyExists = -11983;
  kPGPError_AssertFailed = -11982;
  kPGPError_BadMemAddress = -11981;
  kPGPError_UnknownError = -11980;

  kPGPError_PrefNotFound = -11979;
  kPGPError_EndOfIteration = -11978;
  kPGPError_ImproperInitialization = -11977;
  kPGPError_CorruptData = -11976;
  kPGPError_FeatureNotAvailable = -11975;
  kPGPError_FirstError = -11500;
  kPGPError_Last = -10500;

  kPGPError_BadPassphrase = -11500;
  kPGPError_OptionNotFound = -11499;

  kPGPError_RedundantOptions = -11498;
  kPGPError_KeyRevoked = -11497;
  kPGPError_KeyExpired = -11496;
  kPGPError_KeyDisabled = -11495;
  kPGPError_KeyInvalid = -11494;
  kPGPError_KeyUnusableForEncryption = -11493;
  kPGPError_KeyUnusableForSignature = -11492;
  kPGPError_OutputBufferTooSmall = -11491;
  kPGPError_InconsistentEncryptionAlgorithms = -11490;
  kPGPError_MissingPassphrase = -11489;
  kPGPError_CombinedConventionalAndPublicEncryption = -11488;
  kPGPError_DetachedSignatureWithoutSigningKey = -11487;
  kPGPError_DetachedSignatureWithEncryption = -11486;
  kPGPError_NoInputOptions = -11485;
  kPGPError_MultipleInputOptions = -11484;
  kPGPError_InputFile = -11483;
  kPGPError_NoOutputOptions = -11482;
  kPGPError_MultipleOutputOptions = -11481;
  kPGPError_MissingEventHandler = -11480;
  kPGPError_MissingKeySet = -11479;
  kPGPError_DetachedSignatureFound = -11478;
  kPGPError_NoDecryptionKeyFound = -11477;
  kPGPError_CorruptSessionKey = -11476;
  kPGPError_SkipSection = -11475;
  kPGPError_Interrupted = -11474;
  kPGPError_TooManyARRKs = -11473;
  kPGPError_KeyUnusableForDecryption = -11472;

  kPGPError_IncompatibleAPI = -11460;
  kPGPError_NotMacBinary = -11450;
  kPGPError_NoMacBinaryTranslationAvailable = -11449;
  kPGPError_BadSignature = -11448;
  kPGPError_CAPIUnsupportedKey = -11447;

  kPGPError_InconsistentFilterClasses = -11440;
  kPGPError_UnsupportedLDAPFilter = -11439;
  kPGPError_UnsupportedHKPFilter = -11438;
  kPGPError_UnknownFilterType = -11437;
  kPGPError_InvalidFilterParameter = -11436;

  kPGPError_OutOfRings = -11420;
  kPGPError_BadHashNumber = -11419;
  kPGPError_BadCipherNumber = -11418;
  kPGPError_BadKeyLength = -11417;
  kPGPError_SizeAdviseFailure = -11416;
  kPGPError_ConfigParseFailure = -11415;
  kPGPError_ConfigParseFailureBadFunction = -11414;
  kPGPError_ConfigParseFailureBadOptions = -11413;
  kPGPError_KeyIsLocked = -11412;
  kPGPError_CantDecrypt = -11411;
  kPGPError_UnknownString2Key = -11410;
  kPGPError_BadSessionKeySize = -11409;
  kPGPError_UnknownVersion = -11408;
  kPGPError_BadSessionKeyAlgorithm = -11407;
  kPGPError_UnknownSignatureType = -11406;
  kPGPError_BadSignatureSize = -11405;
  kPGPError_SignatureBitsWrong = -11404;
  kPGPError_ExtraDateOnSignature = -11403;
  kPGPError_SecretKeyNotFound = -11402;
  kPGPError_AdditionalRecipientRequestKeyNotFound = -11401;
  kPGPError_InvalidCommit = -11400;
  kPGPError_CantHash = -11399;
  kPGPError_UnbalancedScope = -11398;
  kPGPError_WrongScope = -11397;
  kPGPError_FIFOReadError = -11396;
  kPGPError_RandomSeedTooSmall = -11395;
  kPGPError_EnvPriorityTooLow = -11394;
  kPGPError_UnknownCharMap = -11393;
  kPGPError_AsciiParseIncomplete = -11392;
  kPGPError_BadPacket = -11391;
  kPGPError_TroubleKeySubKey = -11390;
  kPGPError_TroubleSigSubKey = -11389;
  kPGPError_TroubleBadTrust = -11388;
  kPGPError_TroubleUnknownPacketByte = -11387;
  kPGPError_TroubleUnexpectedSubKey = -11386;
  kPGPError_TroubleUnexpectedName = -11385;
  kPGPError_TroubleUnexpectedSignature = -11384;
  kPGPError_TroubleUnexpectedUnknown = -11383;
  kPGPError_TroubleUnexpectedTrust = -11382;
  kPGPError_TroubleKeyTooBig = -11381;
  kPGPError_TroubleSecretKeyTooBig = -11380;
  kPGPError_TroubleNameTooBig = -11379;
  kPGPError_TroubleSignatureTooBig = -11378;
  kPGPError_TroubleUnknownTooBig = -11377;
  kPGPError_TroubleDuplicateKeyID = -11376;
  kPGPError_TroubleDuplicateKey = -11375;
  kPGPError_TroubleDuplicateSecretKey = -11374;
  kPGPError_TroubleDuplicateName = -11373;
  kPGPError_TroubleDuplicateSignature = -11372;
  kPGPError_TroubleDuplicateUnknown = -11371;
  kPGPError_TroubleBareKey = -11370;
  kPGPError_TroubleVersionBugPrev = -11369;
  kPGPError_TroubleVersionBugCur = -11368;
  kPGPError_TroubleOldSecretKey = -11367;
  kPGPError_TroubleNewSecretKey = -11366;
  kPGPError_TroubleImportingNonexportableSignature = -11365;

  kPGPError_KeyPacketTruncated = -11349;
  kPGPError_UnknownKeyVersion = -11348;
  kPGPError_UnknownPublicKeyAlgorithm = -11347;
  kPGPError_MalformedKeyModulus = -11346;
  kPGPError_MalformedKeyExponent = -11345;
  kPGPError_RSAPublicModulusIsEven = -11344;
  kPGPError_RSAPublicExponentIsEven = -11343;
  kPGPError_MalformedKeyComponent = -11342;
  kPGPError_KeyTooLarge = -11341;
  kPGPError_PublicKeyTooSmall = -11340;
  kPGPError_PublicKeyTooLarge = -11339;
  kPGPError_PublicKeyUnimplemented = -11338;

  kPGPError_TruncatedSignature = -11329;
  kPGPError_MalformedSignatureInteger = -11328;
  kPGPError_UnknownSignatureAlgorithm = -11327;
  kPGPError_ExtraSignatureMaterial = -11326;
  kPGPError_UnknownSignatureVersion = -11325;
  kPGPError_RevocationKeyNotFound = -11324;

  kPGPError_OutOfEntropy = -11320;
  kPGPError_ItemIsReadOnly = -11319;
  kPGPError_InvalidProperty = -11318;
  kPGPError_FileCorrupt = -11317;
  kPGPError_DuplicateCert = -11316;
  kPGPError_DuplicateUserID = -11315;
  kPGPError_CertifyingKeyDead = -11314;
  kPGPError_ItemWasDeleted = -11313;
  kPGPError_KeyDBMismatch = -11312;

  kPGPError_ServerInProgress = -11300;
  kPGPError_ServerOperationNotSupported = -11299;
  kPGPError_ServerInvalidProtocol = -11298;
  kPGPError_ServerRequestFailed = -11297;
  kPGPError_ServerOpen = -11296;
  kPGPError_ServerNotOpen = -11295;
  kPGPError_ServerKeyAlreadyExists = -11294;
  kPGPError_ServerNotInitialized = -11293;
  kPGPError_ServerPartialAddFailure = -11292;
  kPGPError_ServerCorruptKeyBlock = -11291;
  kPGPError_ServerUnknownResponse = -11290;
  kPGPError_ServerTimedOut = -11289;
  kPGPError_ServerOpenFailed = -11288;
  kPGPError_ServerAuthorizationRequired = -11287;
  kPGPError_ServerAuthorizationFailed = -11286;
  kPGPError_ServerSearchFailed = -11285;
  kPGPError_ServerPartialSearchResults = -11284;
  kPGPError_ServerBadKeysInSearchResults = -11283;
  kPGPError_ServerKeyFailedPolicy = -11282;
  kPGPError_ServerOperationRequiresTLS = -11281;
  kPGPError_ServerNoStaticStorage = -11280;

  kPGPError_TLSUnexpectedClose = -11250;
  kPGPError_TLSProtocolViolation = -11249;
  kPGPError_TLSVersionUnsupported = -11248;
  kPGPError_TLSWrongState = -11247;
  kPGPError_TLSAlertReceived = -11246;
  kPGPError_TLSKeyUnusable = -11245;
  kPGPError_TLSNoCommonCipher = -11244;
  kPGPError_TLSWouldBlock = -11243;
  kPGPError_TLSRcvdHandshakeRequest = -11242;

  kPGPError_X509NeededCertNotAvailable = -11240;
  kPGPError_X509SelfSignedCert = -11239;
  kPGPError_X509InvalidCertificateSignature = -11238;
  kPGPError_X509InvalidCertificateFormat = -11237;

  kPGPError_BigNumNoInverse = -11150;

  kPGPError_SocketsNetworkDown = -11100;
  kPGPError_SocketsNotInitialized = -11099;
  kPGPError_SocketsInProgress = -11098;
  kPGPError_SocketsNotConnected = -11097;
  kPGPError_SocketsNotBound = -11096;
  kPGPError_SocketsOperationNotSupported = -11095;
  kPGPError_SocketsProtocolNotSupported = -11094;
  kPGPError_SocketsAddressFamilyNotSupported = -11093;
  kPGPError_SocketsNotASocket = -11092;
  kPGPError_SocketsAddressInUse = -11091;
  kPGPError_SocketsBufferOverflow = -11090;
  kPGPError_SocketsListenQueueFull = -11089;
  kPGPError_SocketsAddressNotAvailable = -11088;
  kPGPError_SocketsAlreadyConnected = -11087;
  kPGPError_SocketsTimedOut = -11086;
  kPGPError_SocketsNoStaticStorage = -11085;

  kPGPError_SocketsHostNotFound = -11050;
  kPGPError_SocketsDomainServerError = -11049;

type
  pPGPContext = pointer;
  pPGPFileSpec = pointer;
  pPGPOptionsList = pointer;


  pPGPKey = pointer;
  pPGPSubKey = pointer;
  pPGPUserID = pointer;
  pPGPSig = pointer;
  pPGPKeySet = pointer;
  pPGPKeyList = pointer;
  pPGPKeyIter = pointer;
  pPGPFilter = pointer;

  TPGPKeyID = record
    opaqueBytes: array[0..33] of PGPByte;
  end;

  pPGPKeyID = ^TPGPKeyID;

  pPGPHashContext = pointer;
  pPGPPublicKeyContext = pointer;
  pPGPPrivateKeyContext = pointer;
  pPGPCBCContext = pointer;
  pPGPCFBContext = pointer;
  pPGPSymmetricCipherContext = pointer;
  pPGPJob = pointer;

  pPGPKeyServer = pointer;
  pPGPtlsSession = pointer;
  pPGPMemoryMgr = pointer;

  TPGPVersion = record
    majorVersion: PGPUINT16;
    minorVersion: PGPUINT16;
  end ;


  TPGPLocalEncodingFlags = PGPFLAGS;

  TPGPMemoryFlags = PGPFLAGS;

  TPGPEventNullData = record
    bytesWritten: PGPFILEOFFSET;
    bytesTotal: PGPFILEOFFSET;
  end;

  TPGPEventErrorData = record
    error: PGPERROR;
    errorArg: Pointer;
  end;

  TPGPEventWarningData = record
    warning: PGPERROR;
    warningArg: Pointer;
  end;

  TPGPEventEntropyData = record
    entropyBitsNeeded: PGPUINT32;
  end;

  TPGPEventPassphraseData = record
    fConventional: PGPBOOLEAN;
    keyset: pPGPKeySet;
  end;

  TPGPEventRecipientsData = record
    recipientSet: pPGPKeySet;
    conventionalPassphraseCount: PGPUINT32;
    keyCount: PGPUINT32;
    keyIDArray: pPGPKEYID;
  end;

  TPGPEventKeyFoundData = record
    keySet: pPGPKeySet;
  end;

  TPGPEventSignatureData = record
    signingKeyID: TPGPKeyID;
    signingKey: pPGPKey;
    checked: PGPBOOLEAN;
    verified: PGPBOOLEAN;
    keyRevoked: PGPBOOLEAN;
    keyDisabled: PGPBOOLEAN;
    keyExpired: PGPBOOLEAN;
    keyMeetsValidityThreshold: PGPBOOLEAN;
    keyValidity: PGPVALIDITY;
    creationTime: PGPTIME;
  end;

  TPGPEventAnalyzeData = record
    sectionType: PGPANALYZETYPE;
  end;

  TPGPEventOutputData = record
    messageType: PGPUINT32;
    suggestedName: PChar;
    forYourEyesOnly: PGPBOOLEAN;
  end;

  TPGPEventBeginLexData = record
    sectionNumber: PGPUINT32;
    sectionOffset: PGPSIZE;
  end;

  TPGPEventEndLexData = record
    sectionNumber: PGPUINT32;
  end;

  TPGPEventKeyGenData = record
    state: PGPUINT32;
  end;

  TPGPEventKeyServerData = record
    keyServerRef: pPGPKeyServer;
    state: PGPUINT32;
  end;

  TPGPEventKeyServerSignData = record
    keyServerRef: pPGPKeyServer;
  end;


  TPGPEventData = record case Word of
      01: (nullData: TPGPEVENTNULLDATA; );
      02: (errorData: TPGPEVENTERRORDATA; );
      03: (warningData: TPGPEVENTWARNINGDATA; );
      04: (entropyData: TPGPEVENTENTROPYDATA; );
      05: (passphraseData: TPGPEVENTPASSPHRASEDATA; );
      06: (recipientsData: TPGPEVENTRECIPIENTSDATA; );
      07: (keyFoundData: TPGPEVENTKEYFOUNDDATA; );
      08: (signatureData: TPGPEVENTSIGNATUREDATA; );
      09: (analyzeData: TPGPEVENTANALYZEDATA; );
      10: (outputData: TPGPEVENTOUTPUTDATA; );
      11: (beginLexData: TPGPEVENTBEGINLEXDATA; );
      12: (endLexData: TPGPEVENTENDLEXDATA; );
      13: (keyGenData: TPGPEVENTKEYGENDATA; );
      14: (keyServerData: TPGPEVENTKEYSERVERDATA; );
      15: (keyServerSignData: TPGPEventKeyServerSignData; );
  end;

  pPGPEvent = ^TPGPEvent;
  TPGPEvent = record
    version: TPGPVersion;
    NextEvent: pPGPEvent;
    job: pPGPJob;
    etype: PGPEventType;
    data: TPGPEventData;
  end;

type
  TPGPEventHandlerProcPtr = function (context: pPGPContext; event: pPGPEvent; UserValue: PGPUserValue): PGPError; cdecl;
  TPGPMemoryAllocationProc = function (Context: pPGPContext; AllocSize: PGPSize; flags: TPGPMemoryFlags;
                                       UserValue: PGPUserValue): pointer; cdecl;
  TPGPMemoryReallocationProc = function (context: pPGPContext; var allocation: Pointer; newAllocationSize: PGPSize;
                                         flags: TPGPMemoryFlags; userValue: PGPUserValue): PGPError; cdecl;
  TPGPMemoryDeallocationProc = function (context: pPGPContext; allocation: Pointer; userValue: PGPUserValue): PGPError; cdecl;

type
  TPGPNewContextStruct = record
    sizeofStruct: PGPUINT32;
    memoryMgr: pPGPMemoryMgr;
  end;

  TPGPAlgorithmInfo = record
    ShortName: array[0..31] of char;
    LongName: array[0..95] of char;
    CopyRight: array[0..127] of char;
    flags: PGPFlags;
    reserved: array[0..15] of PGPUInt32;
  end;

  TPGPPublicKeyAlgorithmInfo = record
    info: TPGPAlgorithmInfo;
    algID: PGPPublicKeyAlgorithm;
    CanEncrypt: PGPBoolean;
    CanDecrypt: PGPBoolean;
    CanSign: PGPBoolean;
    CanVerify: PGPBoolean;
    CanGenerate: PGPBoolean;
    reserved1: PGPBoolean;
    reserved2: PGPBoolean;
    reserved3: PGPBoolean;
    reserved: array[0..7] of PGPUInt32;
  end;

  TPGPSymmetricCipherInfo = record
    info: TPGPAlgorithmInfo;
    algID: PGPCipherAlgorithm;
    reserved: array[0..7] of PGPUInt32;
  end;

  pPGPKeyServerMonitorValues = ^TPGPKeyServerMonitorValues;
  TPGPKeyServerMonitorValues = record
    name: PChar;
    values: PPChar;
    next: pPGPKeyServerMonitorValues;
  end;

  pPGPKeyServerMonitor = ^TPGPKeyServerMonitor;
  TPGPKeyServerMonitor = record
    keyServerRef: pPGPKeyServer;
    valuesHead: pPGPKeyServerMonitorValues;
  end;


var
  PGPsdkInit: function: PGPERROR; cdecl;
  PGPsdkCleanup: function: PGPERROR; cdecl;
  PGPNewContext: function (clientAPIVersion: PGPUINT32; var newContext: pPGPContext): PGPERROR; cdecl;
  PGPNewContextCustom: function (clientAPIVersion: PGPUINT32; var custom: TPGPNEWCONTEXTSTRUCT;
                                 var newContext: pPGPContext): PGPERROR; cdecl;
  PGPFreeContext: function (context: pPGPContext): PGPERROR; cdecl;
  PGPGetContextUserValue: function (context: pPGPContext; var userValue: PGPUSERVALUE): PGPERROR; cdecl;
  PGPSetContextUserValue: function (context: pPGPContext; userValue: PGPUSERVALUE): PGPERROR; cdecl;
  PGPContextGetRandomBytes: function (context: pPGPContext; byteBuffer: Pointer; len: PGPSIZE): PGPERROR; cdecl;
  PGPGetContextMemoryMgr: function (context: pPGPContext): pPGPMemoryMgr; cdecl;


var
  PGPNewData: function (memoryMgr: pPGPMemoryMgr; requestSize: PGPSIZE; flags: TPGPMemoryFlags): pointer; cdecl;

var
  PGPNewSecureData: function (memoryMgr: pPGPMemoryMgr; requestSize: PGPSIZE; flags: TPGPMemoryFlags): pointer; cdecl;

var
  PGPFreeData: function (allocation: Pointer): PGPERROR; cdecl;


var
  PGPCopyFileSpec: function (fileRef: pPGPFileSpec; var ref: pPGPFileSpec): PGPERROR; cdecl;

var
  PGPFreeFileSpec: function (fileRef: pPGPFileSpec): PGPERROR; cdecl;

var
  PGPNewFileSpecFromFullPath: function (context: pPGPContext; path: PChar; var ref: pPGPFileSpec): PGPERROR; cdecl;

var
  PGPGetFullPathFromFileSpec: function (fileRef: pPGPFileSpec; var fullPathPtr: PChar): PGPERROR; cdecl;


var
  PGPGetTime: function: PGPTIME; cdecl;

var
  PGPGetStdTimeFromPGPTime: function (theTime: PGPTIME): TIME_T; cdecl;
var
  PGPGetPGPTimeFromStdTime: function (theTime: TIME_T): PGPTIME; cdecl;

var
  PGPGetYMDFromPGPTime: procedure (theTime: PGPTIME; var year: PGPUINT16; var month: PGPUINT16; var day: PGPUINT16); cdecl;

var
  PGPGlobalRandomPoolAddKeystroke: function (event: PGPINT32): PGPUINT32; cdecl;
var
  PGPGlobalRandomPoolAddMouse: function (x: PGPUINT32; y: PGPUINT32): PGPUINT32; cdecl;
var
  PGPGlobalRandomPoolGetEntropy: function: PGPUINT32; cdecl;
var
  PGPGlobalRandomPoolGetSize: function: PGPUINT32; cdecl;
var
  PGPGlobalRandomPoolGetMinimumEntropy: function: PGPUINT32; cdecl;
var
  PGPGlobalRandomPoolHasMinimumEntropy: function: PGPBOOLEAN; cdecl;

var
  PGPGetErrorString: function (theError: PGPERROR; bufferSize: PGPSIZE; theString: PChar): PGPERROR; cdecl;


var
  PGPGetSDKVersion: function (var version: PGPUINT32): PGPERROR; cdecl;

var
  PGPGetSDKString: function (var TheString: PGPString): PGPERROR; cdecl;

var
  PGPGetFeatureFlags: function (selector: PGPFeatureSelector; var flags: PGPFlags): PGPERROR; cdecl;

var
  PGPCountPublicKeyAlgorithms: function (var numPKAlgs: PGPUInt32): PGPError; cdecl;

var
  PGPGetIndexedPublicKeyAlgorithmInfo: function (index: PGPUInt32; var info: TPGPPublicKeyAlgorithmInfo): PGPError; cdecl;

var
  PGPCountSymmetricCiphers: function (var numPKAlgs: PGPUInt32): PGPError; cdecl;

var
  PGPGetIndexedSymmetricCipherInfo: function (index: PGPUInt32; var info: TPGPSymmetricCipherInfo): PGPError; cdecl;


var
  PGPsdkLoadPrefs: function (context: pPGPContext; prefSpec: pPGPFileSpec): PGPError; cdecl;

var
  PGPsdkLoadDefaultPrefs: function (context: pPGPContext): PGPError; cdecl;

var
  PGPsdkSavePrefs: function (context: pPGPContext): PGPError; cdecl;

var
  PGPsdkPrefSetFileSpec: function (context: pPGPContext; selector: PGPsdkPrefSelector; ref: pPGPFileSpec): PGPError; cdecl;

var
  PGPsdkPrefGetFileSpec: function (context: pPGPContext; selector: PGPsdkPrefSelector; var outRef: pPGPFileSpec): PGPError; cdecl;

var
  PGPsdkPrefSetData: function (context: pPGPContext; selector: PGPsdkPrefSelector; data: Pointer; size: PGPSize): PGPError; cdecl;

var
  PGPsdkPrefGetData: function (context: pPGPContext; selector: PGPsdkPrefSelector; var dataOut: Pointer;
                               var sizeOut: PGPSize): PGPError; cdecl;


var
  PGPNewOptionList: function (context: pPGPContext; var outList: pPGPOptionsList): PGPERROR; cdecl;

var
  PGPCopyOptionList: function (optionList: pPGPOptionsList;var outList: pPGPOptionsList): PGPERROR; cdecl;

var
  PGPFreeOptionList: function (optionList: pPGPOptionsList): PGPERROR; cdecl;

function PGPAddJobOptions (job: pPGPJob; Args: array of pPGPOptionsList): PGPError;

function PGPAppendOptionList (optionList: pPGPOptionsList; Args: array of pPGPOptionsList): PGPError; cdecl;

function PGPBuildOptionList (context: pPGPContext; var outList: pPGPOptionsList; Args: array of pPGPOptionsList): PGPError; cdecl;

var
  PGPOLastOption: function (context: pPGPContext): pPGPOptionsList; cdecl;

var
  PGPONullOption: function (context: pPGPContext): pPGPOptionsList; cdecl;


var
  PGPIncFilterRefCount: function (filter: pPGPFilter): PGPERROR; cdecl;

var
  PGPFreeFilter: function (filter: pPGPFilter): PGPERROR; cdecl;

var
  PGPNewKeyIDFilter: function (context: pPGPContext; var keyID: TPGPKeyID; var outFilter: pPGPFilter): PGPERROR; cdecl;

var
  PGPNewSubKeyIDFilter: function (context: pPGPContext; var ubKeyID: TPGPKeyID; var outFilter: pPGPFilter): PGPERROR; cdecl;

var
  PGPNewKeyEncryptAlgorithmFilter: function (context: pPGPContext; encryptAlgorithm: PGPPUBLICKEYALGORITHM;
                                             var outFilter: pPGPFilter): PGPERROR; cdecl;

var
  PGPNewKeyFingerPrintFilter: function (context: pPGPContext; fingerPrint: Pointer; fingerPrintLength: PGPSIZE;
                                        var outFilter: pPGPFilter): PGPERROR; cdecl;

var
  PGPNewKeyCreationTimeFilter: function (context: pPGPContext; creationTime: PGPTIME; match: PGPMATCHCRITERION;
                                         var outFilter: pPGPFilter): PGPERROR; cdecl;

var
  PGPNewKeyExpirationTimeFilter: function (context: pPGPContext; expirationTime: PGPTIME; match: PGPMATCHCRITERION;
                                           var outFilter: pPGPFilter): PGPERROR; cdecl;

var
  PGPNewKeyRevokedFilter: function (context: pPGPContext; revoked: PGPBOOLEAN; var outFilter: pPGPFilter): PGPERROR; cdecl;

var
  PGPNewKeyDisabledFilter: function (context: pPGPContext; disabled: PGPBOOLEAN; var outFilter: pPGPFilter): PGPERROR; cdecl;

var
  PGPNewKeySigAlgorithmFilter: function (context: pPGPContext; sigAlgorithm: PGPPUBLICKEYALGORITHM;
                                         var outFilter: pPGPFilter): PGPERROR; cdecl;

var
  PGPNewKeyEncryptKeySizeFilter: function (context: pPGPContext; keySize: PGPUINT32; match: PGPMATCHCRITERION;
                                           var outFilter: pPGPFilter): PGPERROR; cdecl;

var
  PGPNewKeySigKeySizeFilter: function (context: pPGPContext; keySize: PGPUINT32; match: PGPMATCHCRITERION;
                                       var outFilter: pPGPFilter): PGPERROR; cdecl;

var
  PGPNewUserIDStringFilter: function (context: pPGPContext; userIDString: PChar; match: PGPMATCHCRITERION;
                                      var outFilter: pPGPFilter): PGPERROR; cdecl;

var
  PGPNewUserIDEmailFilter: function (context: pPGPContext; emailString: PChar; match: PGPMATCHCRITERION;
                                     var outFilter: pPGPFilter): PGPERROR; cdecl;

var
  PGPNewUserIDNameFilter: function (context: pPGPContext; nameString: PChar; match: PGPMATCHCRITERION;
                                    var outFilter: pPGPFilter): PGPERROR; cdecl;

var
  PGPNewSigKeyIDFilter: function (context: pPGPContext; var keyID: TPGPKeyID; var outFilter: pPGPFilter): PGPERROR; cdecl;

var
  PGPNegateFilter: function (filter: pPGPFilter; var outFilter: pPGPFilter): PGPERROR; cdecl;

var
  PGPIntersectFilters: function (filter1: pPGPFilter; filter2: pPGPFilter; var outFilter: pPGPFilter): PGPERROR; cdecl;

var
  PGPUnionFilters: function (filter1: pPGPFilter; filter2: pPGPFilter; var outFilter: pPGPFilter): PGPERROR; cdecl;

var
  PGPFilterKeySet: function (origSet: pPGPKeySet; filter: pPGPFilter; var resultSet: pPGPKeySet): PGPERROR; cdecl;


var
  PGPLDAPQueryFromFilter: function (filter: pPGPFilter; var queryOut: PChar): PGPERROR; cdecl;
  PGPHKSQueryFromFilter: function (filter: pPGPFilter; var queryOut: PChar): PGPERROR; cdecl;


var
  PGPNewKeySet: function (context: pPGPContext; var keySet: pPGPKeySet): PGPERROR; cdecl;


var
  PGPNewEmptyKeySet: function (origSet: pPGPKeySet; var newSet: pPGPKeySet): PGPERROR; cdecl;
  PGPNewSingletonKeySet: function (key: pPGPKey; var keySet: pPGPKeySet): PGPERROR; cdecl;
  PGPUnionKeySets: function (set1: pPGPKeySet; set2: pPGPKeySet; var newSet: pPGPKeySet): PGPERROR; cdecl;
  PGPOpenDefaultKeyRings: function (context: pPGPContext; openFlags: PGPKEYRINGOPENFLAGS; var keySet: pPGPKeySet): PGPERROR; cdecl;
  PGPOpenKeyRingPair: function (context: pPGPContext; openFlags: PGPKEYRINGOPENFLAGS; pubFileRef: pPGPFileSpec;
                                secFileRef: pPGPFileSpec; var keySet: pPGPKeySet): PGPERROR; cdecl;
  PGPOpenKeyRing: function (context: pPGPContext; openFlags: PGPKEYRINGOPENFLAGS; fileRef: pPGPFileSpec;
                            var keySet: pPGPKeySet): PGPERROR; cdecl;
  PGPCommitKeyRingChanges: function (keys: pPGPKeySet): PGPERROR; cdecl;
  PGPPropagateTrust: function (keys: pPGPKeySet): PGPERROR; cdecl;
  PGPRevertKeyRingChanges: function (keys: pPGPKeySet): PGPERROR; cdecl;
  PGPCheckKeyRingSigs: function (keysToCheck: pPGPKeySet; keysSigning: pPGPKeySet; checkAll: PGPBOOLEAN;
                                 progress: TPGPEVENTHANDLERPROCPTR; userValue: PGPUSERVALUE): PGPERROR; cdecl;
  PGPReloadKeyRings: function (keys: pPGPKeySet): PGPERROR; cdecl;
  PGPGetKeyByKeyID: function (keys: pPGPKeySet; var keyID: TPGPKeyID; pubKeyAlgorithm: PGPPUBLICKEYALGORITHM;
                              var outRef: pPGPKey): PGPERROR; cdecl;
  PGPKeySetIsMember: function (key: pPGPKey; aset: pPGPKeySet): PGPBOOLEAN; cdecl;
  PGPCountKeys: function (keys: pPGPKeySet; var numKeys: PGPUINT32): PGPERROR; cdecl;
  PGPIncKeySetRefCount: function (keys: pPGPKeySet): PGPERROR; cdecl;
  PGPFreeKeySet: function (keys: pPGPKeySet): PGPERROR; cdecl;
  PGPKeySetIsMutable: function (keys: pPGPKeySet): PGPBOOLEAN; cdecl;
  PGPKeySetNeedsCommit: function (keys: pPGPKeySet): PGPBOOLEAN; cdecl;
  PGPAddKeys: function (keysToAdd: pPGPKeySet; aset: pPGPKeySet): PGPERROR; cdecl;
  PGPRemoveKeys: function (keysToRemove: pPGPKeySet; aset: pPGPKeySet): PGPERROR; cdecl;


var
  PGPDisableKey: function (key: pPGPKey): PGPERROR; cdecl;
  PGPEnableKey: function (key: pPGPKey): PGPERROR; cdecl;
  PGPRemoveSubKey: function (subkey: pPGPSubKey): PGPERROR; cdecl;
  PGPRemoveUserID: function (userID: pPGPUserID): PGPERROR; cdecl;
  PGPSetPrimaryUserID: function (userid: pPGPUserID): PGPERROR; cdecl;
  PGPGetSigCertifierKey: function (cert: pPGPSig; allkeys: pPGPKeySet; var certkey: pPGPKey): PGPERROR; cdecl;
  PGPRemoveSig: function (cert: pPGPSig): PGPERROR; cdecl;
  PGPCountAdditionalRecipientRequests: function (basekey: pPGPKey; var numARKeys: PGPUINT32): PGPERROR; cdecl;
  PGPGetIndexedAdditionalRecipientRequestKey: function (basekey: pPGPKey; allkeys: pPGPKeySet; nth: PGPUINT32; var arkey: pPGPKey;
                                                        var arkeyid: TPGPKeyID; var arclass: PGPBYTE): PGPERROR; cdecl;

function PGPChangeSubKeyPassphrase (subkey: pPGPSubKey; Args: array of pPGPOptionsList): PGPError; cdecl;
function PGPPassphraseIsValid (key: pPGPKey; Args: array of pPGPOptionsList): PGPBoolean; cdecl;

function PGPGenerateKey (context: pPGPContext; var key: pPGPKey; args: array of pPGPOptionsList): PGPError; cdecl;
function PGPGenerateSubKey (context: pPGPContext; var subkey: pPGPSubkey; Args: array of pPGPOptionsList): PGPError; cdecl;
function PGPGetKeyEntropyNeeded (context: pPGPContext; Args: array of pPGPOptionsList): PGPUInt32; cdecl;
function PGPExportKeySet (keys: pPGPKeySet; Args: array of pPGPOptionsList): PGPError; cdecl;
function PGPImportKeySet (context: pPGPContext; var keys: pPGPKeyset; Args: array of pPGPOptionsList): PGPError; cdecl;
function PGPSignUserID (userID: pPGPUserID; certifyingKey: pPGPKey; Args: array of pPGPOptionsList): PGPError; cdecl;
function PGPAddUserID (key: pPGPKey; const userID: PChar; Args: array of pPGPOptionsList): PGPError; cdecl;
function PGPRevokeSig (cert: pPGPSig; allkeys: pPGPKeySet; Args: array of pPGPOptionsList): PGPError; cdecl;
function PGPRevokeKey (key: pPGPKey; Args: array of pPGPOptionsList): PGPError; cdecl;
function PGPRevokeSubKey (subkey: pPGPSubKey; Args: array of pPGPOptionsList): PGPError; cdecl;


var
  PGPSetKeyTrust: function (key: pPGPKey; trust: PGPUINT32): PGPERROR; cdecl;
  PGPUnsetKeyAxiomatic: function (key: pPGPKey): PGPERROR; cdecl;

function PGPSetKeyAxiomatic (key: pPGPKey; Args: array of pPGPOptionsList): PGPError; cdecl;


var
  PGPGetKeyBoolean: function (key: pPGPKey; propname: PGPKEYPROPNAME; var prop: PGPBOOLEAN): PGPERROR; cdecl;
  PGPGetKeyNumber: function (key: pPGPKey; propname: PGPKEYPROPNAME; var prop: PGPINT32): PGPERROR; cdecl;


var
  PGPGetKeyPropertyBuffer: function (key: pPGPKey; propname: PGPKEYPROPNAME; bufferSize: PGPSIZE; data: Pointer;
                                     var fullSize: PGPSIZE): PGPERROR; cdecl;
  PGPGetKeyTime: function (key: pPGPKey; propname: PGPKEYPROPNAME; var prop: PGPTIME): PGPERROR; cdecl;
  PGPGetSubKeyBoolean: function (subkey: pPGPSubKey; propname: PGPKEYPROPNAME; var prop: PGPBOOLEAN): PGPERROR; cdecl;
  PGPGetSubKeyNumber: function (subkey: pPGPSubKey; propname: PGPKEYPROPNAME; var prop: PGPINT32): PGPERROR; cdecl;


var
  PGPGetSubKeyPropertyBuffer: function (subkey: pPGPSubKey; propname: PGPKEYPROPNAME; bufferSize: PGPSIZE; prop: Pointer;
                                        var fullSize: PGPSIZE): PGPERROR; cdecl;
  PGPGetSubKeyTime: function (subkey: pPGPSubKey; propname: PGPKEYPROPNAME; var prop: PGPTIME): PGPERROR; cdecl;
  PGPGetUserIDNumber: function (userID: pPGPUserID; propname: PGPUSERIDPROPNAME; var prop: PGPINT32): PGPERROR; cdecl;


var
  PGPGetUserIDStringBuffer: function (userID: pPGPUserID; propname: PGPUSERIDPROPNAME; bufferSize: PGPSIZE; astring: PChar;
                                      var fullSize: PGPSIZE): PGPERROR; cdecl;
  PGPGetSigBoolean: function (cert: pPGPSig; propname: PGPSIGPROPNAME; var prop: PGPBOOLEAN): PGPERROR; cdecl;
  PGPGetSigNumber: function (cert: pPGPSig; propname: PGPSIGPROPNAME; var prop: PGPINT32): PGPERROR; cdecl;
  PGPGetKeyIDOfCertifier: function (sig: pPGPSig; var outID: TPGPKeyID): PGPERROR; cdecl;
  PGPGetSigTime: function (cert: pPGPSig; propname: PGPSIGPROPNAME; var prop: PGPTIME): PGPERROR; cdecl;
  PGPGetHashAlgUsed: function (key: pPGPKey; var hashAlg: PGPHASHALGORITHM): PGPERROR; cdecl;


var
  PGPGetPrimaryUserID: function (key: pPGPKey; var outRef: pPGPUserID): PGPERROR; cdecl;


var
  PGPGetPrimaryUserIDNameBuffer: function (key: pPGPKey; bufferSize: PGPSIZE; atring: PChar;
                                           var fullSize: PGPSIZE): PGPERROR; cdecl;
  PGPGetPrimaryUserIDValidity: function (key: pPGPKey; var validity: PGPVALIDITY): PGPERROR; cdecl;
  PGPCompareKeys: function (a: pPGPKey; b: pPGPKey; order: PGPKEYORDERING): PGPINT32; cdecl;
  PGPCompareUserIDStrings: function (a: PChar; b: PChar): PGPINT32; cdecl;
  PGPOrderKeySet: function (src: pPGPKeySet; order: PGPKEYORDERING; var outRef: pPGPKeyList): PGPERROR; cdecl;
  PGPIncKeyListRefCount: function (keys: pPGPKeyList): PGPERROR; cdecl;
  PGPFreeKeyList: function (keys: pPGPKeyList): PGPERROR; cdecl;


var
  PGPNewKeyIter: function (keys: pPGPKeyList; var outRef: pPGPKeyIter): PGPERROR; cdecl;
  PGPCopyKeyIter: function (orig: pPGPKeyIter; var outRef: pPGPKeyIter): PGPERROR; cdecl;
  PGPFreeKeyIter: function (iter: pPGPKeyIter): PGPERROR; cdecl;
  PGPKeyIterIndex: function (iter: pPGPKeyIter): PGPINT32; cdecl;
  PGPKeyIterRewind: function (iter: pPGPKeyIter): PGPERROR; cdecl;
  PGPKeyIterSeek: function (iter: pPGPKeyIter; key: pPGPKey): PGPINT32; cdecl;
  PGPKeyIterMove: function (iter: pPGPKeyIter; relOffset: PGPINT32; var outRef: pPGPKey): PGPERROR; cdecl;
  PGPKeyIterNext: function (iter: pPGPKeyIter; var outRef: pPGPKey): PGPERROR; cdecl;
  PGPKeyIterPrev: function (iter: pPGPKeyIter; var outRef: pPGPKey): PGPERROR; cdecl;
  PGPKeyIterKey: function (iter: pPGPKeyIter; var outRef: pPGPKey): PGPERROR; cdecl;
  PGPKeyIterSubKey: function (iter: pPGPKeyIter; var outRef: pPGPSubKey): PGPERROR; cdecl;
  PGPKeyIterUserID: function (iter: pPGPKeyIter; var outRef: pPGPUserID): PGPERROR; cdecl;
  PGPKeyIterSig: function (iter: pPGPKeyIter; var outRef: pPGPSig): PGPERROR; cdecl;
  PGPKeyIterNextSubKey: function (iter: pPGPKeyIter; var outRef: pPGPSubKey): PGPERROR; cdecl;
  PGPKeyIterPrevSubKey: function (iter: pPGPKeyIter; var outRef: pPGPSubKey): PGPERROR; cdecl;
  PGPKeyIterRewindSubKey: function (iter: pPGPKeyIter): PGPERROR; cdecl;
  PGPKeyIterNextUserID: function (iter: pPGPKeyIter; var outRef: pPGPUserID): PGPERROR; cdecl;
  PGPKeyIterPrevUserID: function (iter: pPGPKeyIter; var outRef: pPGPUserID): PGPERROR; cdecl;
  PGPKeyIterRewindUserID: function (iter: pPGPKeyIter): PGPERROR; cdecl;
  PGPKeyIterNextUIDSig: function (iter: pPGPKeyIter; var outRef: pPGPSig): PGPERROR; cdecl;
  PGPKeyIterPrevUIDSig: function (iter: pPGPKeyIter; var outRef: pPGPSig): PGPERROR; cdecl;
  PGPKeyIterRewindUIDSig: function (iter: pPGPKeyIter): PGPERROR; cdecl;


var
  PGPGetDefaultPrivateKey: function (keyset: pPGPKeySet; var outRef: pPGPKey): PGPERROR; cdecl;
  PGPSetDefaultPrivateKey: function (key: pPGPKey): PGPERROR; cdecl;


var
  PGPSetKeyUserVal: function (key: pPGPKey; userValue: PGPUSERVALUE): PGPERROR; cdecl;
  PGPSetUserIDUserVal: function (userid: pPGPUserID; userValue: PGPUSERVALUE): PGPERROR; cdecl;
  PGPSetSubKeyUserVal: function (subkey: pPGPSubKey; userValue: PGPUSERVALUE): PGPERROR; cdecl;
  PGPSetSigUserVal: function (cert: pPGPSig; userValue: PGPUSERVALUE): PGPERROR; cdecl;
  PGPGetKeyUserVal: function (key: pPGPKey; var userValue: PGPUSERVALUE): PGPERROR; cdecl;
  PGPGetUserIDUserVal: function (userid: pPGPUserID; var userValue: PGPUSERVALUE): PGPERROR; cdecl;
  PGPGetSubKeyUserVal: function (subkey: pPGPSubKey; var userValue: PGPUSERVALUE): PGPERROR; cdecl;
  PGPGetSigUserVal: function (cert: pPGPSig; var userValue: PGPUSERVALUE): PGPERROR; cdecl;


var
  PGPGetKeyIDFromString: function (astring: PChar;
    var id: TPGPKeyID): PGPERROR; cdecl;

var
  PGPGetKeyIDFromKey: function (key: pPGPKey;
    var id: TPGPKeyID): PGPERROR; cdecl;

var
  PGPGetKeyIDFromSubKey: function (key: pPGPSubKey;
    var id: TPGPKeyID): PGPERROR; cdecl;

type
  PGPChar = array[0..KPGPMAXKEYIDSTRINGSIZE] of char;

var
  PGPGetKeyIDString: function (var ref: TPGPKeyID; atype: PGPKEYIDSTRINGTYPE; outstring: PGPChar): PGPERROR; cdecl;

const
  kPGPMaxExportedKeyIDSize = (sizeof (TPGPKeyID));

type
  PGPByteArray = array[0..kPGPMaxExportedKeyIDSize] of char;

var
  PGPExportKeyID: function (var keyID: TPGPKeyID; EXPORTEDDATA: PGPByteArray; var exportedLength: PGPSIZE): PGPERROR; cdecl;


var
  PGPImportKeyID: function (data: Pointer; var id: TPGPKeyID): PGPERROR; cdecl;


var
  PGPCompareKeyIDs: function (var key: TPGPKeyID; var key2: TPGPKeyID): PGPINT32; cdecl;


var
  PGPGetKeyListContext: function (ref: pPGPKeyList): pPGPContext; cdecl;
  PGPGetKeySetContext: function (ref: pPGPKeySet): pPGPContext; cdecl;
  PGPGetKeyIterContext: function (ref: pPGPKeyIter): pPGPContext; cdecl;
  PGPGetKeyContext: function (ref: pPGPKey): pPGPContext; cdecl;
  PGPGetSubKeyContext: function (ref: pPGPSubKey): pPGPContext; cdecl;
  PGPGetUserIDContext: function (ref: pPGPUserID): pPGPContext; cdecl;


var
  PGPNewPublicKeyContext: function (publicKeyRef: pPGPKey; messageFormat: PGPPublicKeyMessageFormat;
                                    var outRef: pPGPPublicKeyContext): PGPERROR; cdecl;

var
  PGPFreePublicKeyContext: function (ref: pPGPPublicKeyContext): PGPERROR; cdecl;

var
  PGPGetPublicKeyOperationSizes: function (ref: pPGPPublicKeyContext; var maxDecryptedBufferSize: PGPSIZE;
                                           var maxEncryptedBufferSize: PGPSIZE; var maxSignatureSize: PGPSIZE): PGPERROR; cdecl;

var
  PGPPublicKeyEncrypt: function (ref: pPGPPublicKeyContext; data: Pointer; inSize: PGPSIZE; dataout: Pointer;
                                 var outSize: PGPSIZE): PGPERROR; cdecl;

var
  PGPPublicKeyVerifySignature: function (ref: pPGPPublicKeyContext; hashContext: pPGPHashContext; signature: Pointer;
                                         signatureSize: PGPSIZE): PGPERROR; cdecl;

function PGPNewPrivateKeyContext (privateKeyRef: pPGPKey; messageFormat: PGPPublicKeyMessageFormat;
                                  var outRef: pPGPPrivateKeyContext; Args: array of pPGPOptionsList): PGPError; cdecl;

var
  PGPFreePrivateKeyContext: function (ref: pPGPPrivateKeyContext): PGPERROR; cdecl;

var
  PGPGetPrivateKeyOperationSizes: function (ref: pPGPPrivateKeyContext; var maxDecryptedBufferSize: PGPSIZE;
                                            var maxEncryptedBufferSize: PGPSIZE; var maxSignatureSize: PGPSIZE): PGPERROR; cdecl;

var
  PGPPrivateKeyDecrypt: function (ref: pPGPPrivateKeyContext; datain: Pointer; inSize: PGPSIZE; dataout: Pointer;
                                  var outSize: PGPSIZE): PGPERROR; cdecl;

var
  PGPPrivateKeySign: function (ref: pPGPPrivateKeyContext; hashContext: pPGPHashContext; signature: Pointer;
                               var signatureSize: PGPSIZE): PGPERROR; cdecl;


var
  PGPNewSymmetricCipherContext: function (memoryMgr: pPGPMemoryMgr; algorithm: PGPCIPHERALGORITHM; keySizeInBytes: PGPSIZE;
                                          var outRef: pPGPSymmetricCipherContext): PGPERROR; cdecl;

var
  PGPFreeSymmetricCipherContext: function (ref: pPGPSymmetricCipherContext): PGPERROR; cdecl;

var
  PGPCopySymmetricCipherContext: function (ref: pPGPSymmetricCipherContext;
                                           var outRef: pPGPSymmetricCipherContext): PGPERROR; cdecl;


var
  PGPInitSymmetricCipher: function (ref: pPGPSymmetricCipherContext; key: Pointer): PGPERROR; cdecl;

var
  PGPWipeSymmetricCipher: function (ref: pPGPSymmetricCipherContext): PGPERROR; cdecl;

var
  PGPWashSymmetricCipher: function (ref: pPGPSymmetricCipherContext; byteBuffer: Pointer; len: PGPSIZE): PGPERROR; cdecl;

var
  PGPSymmetricCipherEncrypt: function (ref: pPGPSymmetricCipherContext; datain: Pointer; dataout: Pointer): PGPERROR; cdecl;


var
  PGPSymmetricCipherDecrypt: function (ref: pPGPSymmetricCipherContext; datain: Pointer; dataout: Pointer): PGPERROR; cdecl;

var
  PGPGetSymmetricCipherSizes: function (ref: pPGPSymmetricCipherContext; var keySize: PGPSIZE;
                                        var blockSize: PGPSIZE): PGPERROR; cdecl;


var
  PGPNewCFBContext: function (ref: pPGPSymmetricCipherContext; interleaveFactor: PGPUINT16;
                              var outRef: pPGPCFBContext): PGPERROR; cdecl;

var
  PGPFreeCFBContext: function (ref: pPGPCFBContext): PGPERROR; cdecl;

var
  PGPCopyCFBContext: function (ref: pPGPCFBContext; var outRef: pPGPCFBContext): PGPERROR; cdecl;

var
  PGPInitCFB: function (ref: pPGPCFBContext; key: Pointer; initializationVector: Pointer): PGPERROR; cdecl;

var
  PGPCFBEncrypt: function (ref: pPGPCFBContext; datain: Pointer; bytesIn: PGPSIZE; dataout: Pointer): PGPERROR; cdecl;


var
  PGPCFBDecrypt: function (ref: pPGPCFBContext; datain: Pointer; bytesIn: PGPSIZE; dataout: Pointer): PGPERROR; cdecl;


var
  PGPCFBGetSymmetricCipher: function (ref: pPGPCFBContext; var outRef: pPGPSymmetricCipherContext): PGPERROR; cdecl;


var
  PGPCFBSync: function (ref: pPGPCFBContext): PGPERROR; cdecl;

var
  PGPCFBGetRandom: function (ref: pPGPCFBContext; requestCount: PGPSIZE; dataout: Pointer; var outCount: PGPSIZE): PGPERROR; cdecl;

var
  PGPCFBRandomCycle: function (ref: pPGPCFBContext; salt: Pointer): PGPERROR; cdecl;

var
  PGPCFBRandomWash: function (ref: pPGPCFBContext; datain: Pointer; bytesIn: PGPSIZE): PGPERROR; cdecl;

var
  PGPNewCBCContext: function (ref: pPGPSymmetricCipherContext; var outRef: pPGPCBCContext): PGPERROR; cdecl;

var
  PGPFreeCBCContext: function (ref: pPGPCBCContext): PGPERROR; cdecl;

var
  PGPCopyCBCContext: function (ref: pPGPCBCContext; var outRef: pPGPCBCContext): PGPERROR; cdecl;

var
  PGPInitCBC: function (ref: pPGPCBCContext; key: Pointer; initializationVector: Pointer): PGPERROR; cdecl;


var
  PGPCBCEncrypt: function (ref: pPGPCBCContext; datain: Pointer; bytesIn: PGPSIZE; dataout: Pointer): PGPERROR; cdecl;

var
  PGPCBCDecrypt: function (ref: pPGPCBCContext; datain: Pointer; bytesIn: PGPSIZE; dataout: Pointer): PGPERROR; cdecl;


var
  PGPCBCGetSymmetricCipher: function (ref: pPGPCBCContext; var outRef: pPGPSymmetricCipherContext): PGPERROR; cdecl;


var
  PGPNewHashContext: function (memoryMgr: pPGPMemoryMgr; algorithm: PGPHASHALGORITHM; var outRef: pPGPHashContext): PGPERROR; cdecl;

var
  PGPFreeHashContext: function (ref: pPGPHashContext): PGPERROR; cdecl;

var
  PGPCopyHashContext: function (ref: pPGPHashContext; var outRef: pPGPHashContext): PGPERROR; cdecl;

var
  PGPResetHash: function (ref: pPGPHashContext): PGPERROR; cdecl;

var
  PGPContinueHash: function (ref: pPGPHashContext; datain: Pointer; numBytes: PGPSIZE): PGPERROR; cdecl;

var
  PGPFinalizeHash: function (ref: pPGPHashContext; hashOut: Pointer): PGPERROR; cdecl;


var
  PGPGetHashSize: function (ref: pPGPHashContext; var hashSize: PGPSIZE): PGPERROR; cdecl;


function PGPEncode (context: pPGPContext; Args: array of pPGPOptionsList): PGPError; cdecl;
function PGPDecode (context: pPGPContext; Args: array of pPGPOptionsList): PGPError;

var
  PGPOInputFile: function (context: pPGPContext; fileRef: pPGPFileSpec): pPGPOptionsList; cdecl;
  PGPOInputBuffer: function (context: pPGPContext; buffer: Pointer; bufferSize: PGPSIZE): pPGPOptionsList; cdecl;


var
  PGPOOutputFile: function (context: pPGPContext; fileRef: pPGPFileSpec): pPGPOptionsList; cdecl;
  PGPOOutputBuffer: function (context: pPGPContext; buffer: Pointer; bufferSize: PGPSIZE;
                              var outputDataLength: PGPSIZE): pPGPOptionsList; cdecl;


var
  PGPOAllocatedOutputBuffer: function (context: pPGPContext; var buffer: Pointer; maximumBufferSize: PGPSIZE;
                                       var actualBufferSize: PGPSIZE): pPGPOptionsList; cdecl;


var
  PGPODiscardOutput: function (context: pPGPContext; discardOutput: PGPBOOLEAN): pPGPOptionsList; cdecl;


function PGPOSignWithKey (context: pPGPContext; keyRef: pPGPKey; Args: array of pPGPOptionsList): pPGPOptionsList; cdecl;
function PGPOConventionalEncrypt (context: pPGPContext; Args: array of pPGPOptionsList): pPGPOptionsList; cdecl;
function PGPODetachedSig (context: pPGPContext; Args: array of pPGPOptionsList): pPGPOptionsList; cdecl;

var
  PGPOEncryptToKey: function (context: pPGPContext; keyRef: pPGPKey): pPGPOptionsList; cdecl;
  PGPOEncryptToKeySet: function (context: pPGPContext; keySetRef: pPGPKeySet): pPGPOptionsList; cdecl;
  PGPOEncryptToUserID: function (context: pPGPContext; userIDRef: pPGPUserID): pPGPOptionsList; cdecl;
  PGPOPassphraseBuffer: function (context: pPGPContext; passphrase: Pointer; passphraseLength: PGPSIZE): pPGPOptionsList; cdecl;
  PGPOPassphrase: function (context: pPGPContext; passphrase: PChar): pPGPOptionsList; cdecl;
  PGPOAskUserForEntropy: function (context: pPGPContext; askUserForEntropy: PGPBOOLEAN): pPGPOptionsList; cdecl;
  PGPORawPGPInput: function (context: pPGPContext; rawPGPInput: PGPBOOLEAN): pPGPOptionsList; cdecl;
  PGPOCompression: function (context: pPGPContext; compression: PGPBOOLEAN): pPGPOptionsList; cdecl;
  PGPOLocalEncoding: function (context: pPGPContext; localEncode: TPGPLOCALENCODINGFLAGS): pPGPOptionsList; cdecl;
  PGPOOutputLineEndType: function (context: pPGPContext; lineEnd: PGPLINEENDTYPE): pPGPOptionsList; cdecl;

type
  TMimeSepArray = array[0..kPGPMimeSeparatorSize - 1] of char;

var
  PGPOPGPMIMEEncoding: function (context: pPGPContext; mimeEncoding: PGPBOOLEAN; var mimeBodyOffset: PGPSIZE;
                                 mimeSeparatorArray: TMimeSepArray): pPGPOptionsList; cdecl;
  PGPOOmitMIMEVersion: function (context: pPGPContext; omitVersion: PGPBOOLEAN): pPGPOptionsList; cdecl;
  PGPOCipherAlgorithm: function (context: pPGPContext; algorithm: PGPCIPHERALGORITHM): pPGPOptionsList; cdecl;
  PGPOHashAlgorithm: function (context: pPGPContext; algorithm: PGPHASHALGORITHM): pPGPOptionsList; cdecl;
  PGPOFailBelowValidity: function (context: pPGPContext; minValidity: PGPVALIDITY): pPGPOptionsList; cdecl;
  PGPOWarnBelowValidity: function (context: pPGPContext; minValidity: PGPVALIDITY): pPGPOptionsList; cdecl;
  PGPOEventHandler: function (context: pPGPContext; handler: TPGPEVENTHANDLERPROCPTR;
                              userValue: PGPUSERVALUE): pPGPOptionsList; cdecl;
  PGPOSendNullEvents: function (context: pPGPContext; approxInterval: PGPTIMEINTERVAL): pPGPOptionsList; cdecl;
  PGPOArmorOutput: function (context: pPGPContext; armorOutput: PGPBOOLEAN): pPGPOptionsList; cdecl;
  PGPODataIsASCII: function (context: pPGPContext; dataIsASCII: PGPBOOLEAN): pPGPOptionsList; cdecl;
  PGPOClearSign: function (context: pPGPContext; clearSign: PGPBOOLEAN): pPGPOptionsList; cdecl;
  PGPOForYourEyesOnly: function (context: pPGPContext; forYourEyesOnly: PGPBOOLEAN): pPGPOptionsList; cdecl;
  PGPOKeySetRef: function (context: pPGPContext; keysetRef: pPGPKeySet): pPGPOptionsList; cdecl;
  PGPOImportKeysTo: function (context: pPGPContext; keysetRef: pPGPKeySet): pPGPOptionsList; cdecl;
  PGPOSendEventIfKeyFound: function (context: pPGPContext; sendEventIfKeyFound: PGPBOOLEAN): pPGPOptionsList; cdecl;
  PGPOPassThroughIfUnrecognized: function (context: pPGPContext; passThroughIfUnrecognized: PGPBOOLEAN): pPGPOptionsList; cdecl;
  PGPOKeyGenParams: function (context: pPGPContext; pubKeyAlg: PGPPUBLICKEYALGORITHM; bits: PGPUINT32): pPGPOptionsList; cdecl;
  PGPOKeyGenName: function (context: pPGPContext; name: Pointer; nameLength: PGPSIZE): pPGPOptionsList; cdecl;
  PGPOExpiration: function (context: pPGPContext; expirationDays: PGPUINT32): pPGPOptionsList; cdecl;
  PGPOAdditionalRecipientRequestKeySet: function (context: pPGPContext; arKeySetRef: pPGPKeySet;
                                                  arkClass: PGPBYTE): pPGPOptionsList; cdecl;
  PGPOKeyGenMasterKey: function (context: pPGPContext; masterKeyRef: pPGPKey): pPGPOptionsList; cdecl;
  PGPOPreferredAlgorithms: function (context: pPGPContext; var prefAlg: PGPCIPHERALGORITHM;
                                     numAlgs: PGPUINT32): pPGPOptionsList; cdecl;
  PGPOKeyGenFast: function (context: pPGPContext; fastGen: PGPBOOLEAN): pPGPOptionsList; cdecl;
  PGPOCommentString: function (context: pPGPContext; comment: PChar): pPGPOptionsList; cdecl;
  PGPOVersionString: function (context: pPGPContext; version: PChar): pPGPOptionsList; cdecl;
  PGPOSigRegularExpression: function (context: pPGPContext; regularExpression: PChar): pPGPOptionsList; cdecl;
  PGPOExportPrivateKeys: function (context: pPGPContext; exportPrivate: PGPBOOLEAN): pPGPOptionsList; cdecl;
  PGPOExportable: function (context: pPGPContext; exportable: PGPBOOLEAN): pPGPOptionsList; cdecl;
  PGPOSigTrust: function (context: pPGPContext; trustLevel: PGPUINT32; trustValue: PGPUINT32): pPGPOptionsList; cdecl;


var
  PGPKeyServerInit: function: PGPERROR; cdecl;
  PGPKeyServerCleanup: function: PGPERROR; cdecl;
  PGPKeyServerOpen: function (keyServer: pPGPKeyServer; tlsSession: pPGPtlsSession): PGPERROR; cdecl;
  PGPKeyServerClose: function (keyServer: pPGPKeyServer): PGPERROR; cdecl;
  PGPNewKeyServerFromURL: function (thecontext: pPGPContext; const url: PChar; accessType: PGPKeyServerAccessType;
                                    keySpace: PGPKeyServerKeySpace; var keyServer: pPGPKeyServer): PGPERROR; cdecl;
  PGPFreeKeyServer: function (keyServer: pPGPKeyServer): PGPERROR; cdecl;
  PGPQueryKeyServer: function (keyServer: pPGPKeyServer; filter: pPGPFilter; var resultSet: pPGPKeySet): PGPERROR; cdecl;
  PGPUploadToKeyServer: function (keyServer: pPGPKeyServer; keysToUpload: pPGPKeySet;
                                  var keysThatFailed: pPGPKeySet): PGPERROR; cdecl;
  PGPDeleteFromKeyServer: function (keyServer: pPGPKeyServer; keysToDelete: pPGPKeySet;
                                    var keysThatFailed: pPGPKeySet): PGPERROR; cdecl;
  PGPDisableFromKeyServer: function (keyServer: pPGPKeyServer; keysToDisable: pPGPKeySet;
                                     var keysThatFailed: pPGPKeySet): PGPERROR; cdecl;
  PGPSetKeyServerEventHandler: function (keyServer: pPGPKeyServer; callBack: TPGPEventHandlerProcPtr;
                                         userData: PGPUserValue): PGPERROR; cdecl;
  PGPGetLastKeyServerErrorString: function (keyServer: pPGPKeyServer; var errorString: PChar): PGPERROR; cdecl;
  PGPNewServerMonitor: function (keyServer: pPGPKeyServer; var monitor: pPGPKeyServerMonitor): PGPERROR; cdecl;
  PGPFreeServerMonitor: function (monitor: pPGPKeyServerMonitor): PGPERROR; cdecl;


procedure   PGPCheckResult (Error: PGPError; const PrependMsg: string);
function    PGPErrorMsg (Error: PGPError): string;
function    PGPDescribeEvent (etype: integer): string;

var
  PGPDLLloaded: boolean = false;
  PGPDLLError: string = '';

function    LoadPGPDLL: Boolean;
procedure   FreePGPDLL;

procedure   InitkPGPKeyProp;
procedure   InitUserIDProp;
procedure   InitSigProp;


implementation


uses
  DebOutU;


var
  PGPEncodeProcPtr, PGPDecodeProcPtr, PGPGenerateKeyProcPtr, PGPGenerateSubKeyProcPtr,
  PGPGetKeyEntropyNeededProcPtr, PGPExportKeySetProcPtr, PGPImportKeySetProcPtr,
  PGPSignUserIDProcPtr, PGPAddUserIDProcPtr, PGPRevokeSigProcPtr, PGPRevokeKeyProcPtr,
  PGPRevokeSubKeyProcPtr, PGPAppendOptionListProcPtr, PGPBuildOptionListProcPtr,
  PGPOSignWithKeyProcPtr, PGPOConventionalEncryptProcPtr, PGPODetachedSigProcPtr,
  PGPAddJobOptionsProcPtr, PGPChangeSubKeyPassphraseProcPtr, PGPPassphraseIsValidProcPtr,
  PGPSetKeyAxiomaticProcPtr, PGPNewPrivateKeyContextProcPtr : pointer;


function    PGPErrorMsg (Error: PGPError): String;
resourcestring
  SUnknownError = 'Unbekannter PGP-Fehler';
var
  I: Integer;
begin
  SetLength (Result, 1028);
  Result[1] := #0;
  I := PGPGetErrorString (Error, 1027, PChar(Result));
  SetLength (Result, StrLen(PChar(Result)));
  if (I <> kPGPError_NoError) then Result := SUnknownError;
  Result := Result + Format (' (%d)', [Error]);
end;


procedure PGPCheckResult (Error: PGPError; const PrependMsg: string);
var
  S: String;
begin
  if (Error <> kPGPError_NoError) then begin
    S := PrependMsg + ': ' + PGPErrorMsg (Error);
    DebOut ('PGP Result: ' + S);
    raise EPGPApi.create (S);
  end;
end;


var
  DLLHandle: HModule;
  DLLName: string;


const
  PGPRequiredFunctions: array[0..39] of PChar = (
    'PGPsdkInit', 'PGPsdkCleanup', 'PGPNewContext', 'PGPFreeContext', 'PGPGetErrorString',
    'PGPOpenDefaultKeyRings', 'PGPNewKeySet', 'PGPFreeKeySet', 'PGPCountKeys', 'PGPAddKeys',
    'PGPCommitKeyRingChanges', 'PGPGetDefaultPrivateKey', 'PGPOrderKeySet', 'PGPFreeKeyList',
    'PGPNewKeyIter', 'PGPFreeKeyIter', 'PGPKeyIterNext', 'PGPGetKeyBoolean', 'PGPGetKeyNumber',
    'PGPGetPrimaryUserIDNameBuffer', 'PGPGetKeyIDString', 'PGPGetStdTimeFromPGPTime',
    'PGPGetYMDFromPGPTime', 'PGPEncode', 'PGPDecode', 'PGPBuildOptionList', 'PGPFreeOptionList',
    'PGPOInputBuffer', 'PGPOOutputBuffer', 'PGPOOutputLineEndType', 'PGPODataIsASCII',
    'PGPOVersionString', 'PGPOCommentString', 'PGPOEventHandler', 'PGPOClearSign',
    'PGPOSignWithKey', 'PGPOPassphrase', 'PGPODiscardOutput', 'PGPOImportKeysTo', 'PGPOKeySetRef'
    );


function    PGPMissingFunctions (H: HModule): string;
var
  I: Integer;
begin
  Result := '';
  for I := Low (PGPRequiredFunctions) to High (PGPRequiredFunctions) do begin
    if (GetProcAddress (H, PGPRequiredFunctions[I]) = nil) then begin
      if (Length (Result) > 0) then Result := Result + ', ';
      Result := Result + PGPRequiredFunctions[I];
    end;
  end;
  if (GetProcAddress (H, 'PGPGetSDKString') = nil) and (GetProcAddress (H, 'PGPGetPGPsdkVersionString') = nil) then begin
    if (Length (Result) > 0) then Result := Result + ', ';
    Result := Result + 'PGPGetSDKString';
  end;
end;


procedure   InitPGPDLL;
const
  DebPrefix = 'PGPApiU.InitPGPDLL: ';

var
  GetSDKVer: function (var version: PGPUINT32): PGPERROR; cdecl;
  I: Integer;
  V: PGPUINT32;
  H: HModule;
  E: PGPError;
  S: string;
  FailReason: string;

const
  DLLNames: array[0..1] of string = ('pgp_sdk.dll', 'pgpsdk.dll');

begin

  DLLName := '';
  kPGPsdkAPIVersion := 0;
  FailReason := '';

  try

    for I := Low (DllNames) to High (DllNames) do begin
      DebOut (DebPrefix + 'Lade ' + DLLNames[I] + '...');
      H := SafeLoadLibrary (PChar(DLLNames[I]));
      try
        if (H > 0) then begin
          @GetSDKVer := GetProcAddress (H, 'PGPGetSDKVersion');
          if (not assigned (GetSDKVer)) then begin
            @GetSDKVer := GetProcAddress (H, 'PGPGetPGPsdkVersion');
          end;
          if (assigned (GetSDKVer)) then begin
            V := 0;
            E := GetSDKVer (V);
            if (E <> kPGPError_NoError) then begin
              DebOut (DebPrefix + 'PGPGetSDKVersion: Fehler ' + IntToStr (E));
            end else begin
              DebOut (DebPrefix + 'Version = ' + IntToHex (V, 8));
              S := PGPMissingFunctions (H);
              if (V < $02000000) then begin
                FailReason := DLLNames[I] + ': Version ' + IntToHex (V, 8) + ' wird nicht unterstützt';
                DebOut (DebPrefix + FailReason);
              end else if (Length (S) > 0) then begin
                FailReason := DLLNames[I] + ': Funktionen fehlen: ' + S;
                DebOut (DebPrefix + FailReason);
              end else if (V > kPGPsdkAPIVersion) then begin
                kPGPsdkAPIVersion := V;
                DLLName := DLLNames[I];
              end;
            end;
          end else begin
            DebOut (DebPrefix + 'PGPGetSDKVersion nicht gefunden.');
          end;
        end else begin
          DebOut (DebPrefix + 'DLL-Fehler: ' + IntToStr (GetLastError));
        end;
      finally
        if (H <> 0) then FreeLibrary (H);
      end;
    end;

  except

    DLLName := '';
    kPGPsdkAPIVersion := 0;

  end;

  if (Length (DLLName) = 0) then begin

    if (Length (FailReason) > 0) then begin
      PGPDLLError := FailReason;
    end else begin
      PGPDLLError := 'PGP nicht installiert';
    end;

    DebOut (DebPrefix + 'PGP nicht installiert.');

  end else begin

    DebOut (DebPrefix + 'Größte gefundene Version: ' + IntToHex (kPGPsdkAPIVersion, 8) + ' in ' + DLLName);

  end;

end;


function    LoadPGPDLL: Boolean;
const
  DebPrefix = 'PGPApiU.LoadPGPDLL: ';

var
  S: string;

begin

  if (DLLName <> '') then begin
    DLLHandle := SafeLoadLibrary (PChar(DLLName));
    if (DLLHandle = 0) then PGPDLLError := DLLName + ': DLL-Fehler ' + IntToStr (GetLastError);
  end else begin
    DLLHandle := 0;
  end;

  PGPDLLloaded := (DLLHandle > 0);

  if (PGPDLLloaded) then begin

    InitkPGPKeyProp;
    InitUserIDProp;
    InitSigProp;

    @PGPNewPublicKeyContext := GetProcAddress (DLLHandle, 'PGPNewPublicKeyContext');
    @PGPFreePublicKeyContext := GetProcAddress (DLLHandle, 'PGPFreePublicKeyContext');
    @PGPGetPublicKeyOperationSizes := GetProcAddress (DLLHandle, 'PGPGetPublicKeyOperationSizes');
    @PGPPublicKeyEncrypt := GetProcAddress (DLLHandle, 'PGPPublicKeyEncrypt');
    @PGPPublicKeyVerifySignature := GetProcAddress (DLLHandle, 'PGPPublicKeyVerifySignature');
    PGPNewPrivateKeyContextProcPtr := GetProcAddress (DLLHandle, 'PGPNewPrivateKeyContext');
    @PGPFreePrivateKeyContext := GetProcAddress (DLLHandle, 'PGPFreePrivateKeyContext');
    @PGPGetPrivateKeyOperationSizes := GetProcAddress (DLLHandle, 'PGPGetPrivateKeyOperationSizes');
    @PGPPrivateKeyDecrypt := GetProcAddress (DLLHandle, 'PGPPrivateKeyDecrypt');
    @PGPPrivateKeySign := GetProcAddress (DLLHandle, 'PGPPrivateKeySign');
    @PGPGlobalRandomPoolAddKeystroke := GetProcAddress (DLLHandle, 'PGPGlobalRandomPoolAddKeystroke');
    @PGPGlobalRandomPoolAddMouse := GetProcAddress (DLLHandle, 'PGPGlobalRandomPoolAddMouse');
    @PGPGlobalRandomPoolGetEntropy := GetProcAddress (DLLHandle, 'PGPGlobalRandomPoolGetEntropy');
    @PGPGlobalRandomPoolGetSize := GetProcAddress (DLLHandle, 'PGPGlobalRandomPoolGetSize');
    @PGPGlobalRandomPoolGetMinimumEntropy := GetProcAddress (DLLHandle, 'PGPGlobalRandomPoolGetMinimumEntropy');
    @PGPGlobalRandomPoolHasMinimumEntropy := GetProcAddress (DLLHandle, 'PGPGlobalRandomPoolHasMinimumEntropy');
    @PGPIncFilterRefCount := GetProcAddress (DLLHandle, 'PGPIncFilterRefCount');
    @PGPFreeFilter := GetProcAddress (DLLHandle, 'PGPFreeFilter');
    @PGPNewKeyIDFilter := GetProcAddress (DLLHandle, 'PGPNewKeyIDFilter');
    @PGPNewSubKeyIDFilter := GetProcAddress (DLLHandle, 'PGPNewSubKeyIDFilter');
    @PGPNewKeyEncryptAlgorithmFilter := GetProcAddress (DLLHandle, 'PGPNewKeyEncryptAlgorithmFilter');
    @PGPNewKeyFingerPrintFilter := GetProcAddress (DLLHandle, 'PGPNewKeyFingerPrintFilter');
    @PGPNewKeyCreationTimeFilter := GetProcAddress (DLLHandle, 'PGPNewKeyCreationTimeFilter');
    @PGPNewKeyExpirationTimeFilter := GetProcAddress (DLLHandle, 'PGPNewKeyExpirationTimeFilter');
    @PGPNewKeyRevokedFilter := GetProcAddress (DLLHandle, 'PGPNewKeyRevokedFilter');
    @PGPNewKeyDisabledFilter := GetProcAddress (DLLHandle, 'PGPNewKeyDisabledFilter');
    @PGPNewKeySigAlgorithmFilter := GetProcAddress (DLLHandle, 'PGPNewKeySigAlgorithmFilter');
    @PGPNewKeyEncryptKeySizeFilter := GetProcAddress (DLLHandle, 'PGPNewKeyEncryptKeySizeFilter');
    @PGPNewKeySigKeySizeFilter := GetProcAddress (DLLHandle, 'PGPNewKeySigKeySizeFilter');
    @PGPNewUserIDStringFilter := GetProcAddress (DLLHandle, 'PGPNewUserIDStringFilter');
    @PGPNewUserIDEmailFilter := GetProcAddress (DLLHandle, 'PGPNewUserIDEmailFilter');
    @PGPNewUserIDNameFilter := GetProcAddress (DLLHandle, 'PGPNewUserIDNameFilter');
    @PGPNewSigKeyIDFilter := GetProcAddress (DLLHandle, 'PGPNewSigKeyIDFilter');
    @PGPNegateFilter := GetProcAddress (DLLHandle, 'PGPNegateFilter');
    @PGPIntersectFilters := GetProcAddress (DLLHandle, 'PGPIntersectFilters');
    @PGPUnionFilters := GetProcAddress (DLLHandle, 'PGPUnionFilters');
    @PGPFilterKeySet := GetProcAddress (DLLHandle, 'PGPFilterKeySet');
    @PGPLDAPQueryFromFilter := GetProcAddress (DLLHandle, 'PGPLDAPQueryFromFilter');
    @PGPHKSQueryFromFilter := GetProcAddress (DLLHandle, 'PGPHKSQueryFromFilter');
    @PGPNewKeySet := GetProcAddress (DLLHandle, 'PGPNewKeySet');
    @PGPNewEmptyKeySet := GetProcAddress (DLLHandle, 'PGPNewEmptyKeySet');
    @PGPNewSingletonKeySet := GetProcAddress (DLLHandle, 'PGPNewSingletonKeySet');
    @PGPUnionKeySets := GetProcAddress (DLLHandle, 'PGPUnionKeySets');
    @PGPOpenDefaultKeyRings := GetProcAddress (DLLHandle, 'PGPOpenDefaultKeyRings');
    @PGPOpenKeyRingPair := GetProcAddress (DLLHandle, 'PGPOpenKeyRingPair');
    @PGPOpenKeyRing := GetProcAddress (DLLHandle, 'PGPOpenKeyRing');
    @PGPCommitKeyRingChanges := GetProcAddress (DLLHandle, 'PGPCommitKeyRingChanges');
    @PGPPropagateTrust := GetProcAddress (DLLHandle, 'PGPPropagateTrust');
    @PGPRevertKeyRingChanges := GetProcAddress (DLLHandle, 'PGPRevertKeyRingChanges');
    @PGPCheckKeyRingSigs := GetProcAddress (DLLHandle, 'PGPCheckKeyRingSigs');
    @PGPReloadKeyRings := GetProcAddress (DLLHandle, 'PGPReloadKeyRings');
    @PGPGetKeyByKeyID := GetProcAddress (DLLHandle, 'PGPGetKeyByKeyID');
    @PGPKeySetIsMember := GetProcAddress (DLLHandle, 'PGPKeySetIsMember');
    @PGPCountKeys := GetProcAddress (DLLHandle, 'PGPCountKeys');
    @PGPIncKeySetRefCount := GetProcAddress (DLLHandle, 'PGPIncKeySetRefCount');
    @PGPFreeKeySet := GetProcAddress (DLLHandle, 'PGPFreeKeySet');
    @PGPKeySetIsMutable := GetProcAddress (DLLHandle, 'PGPKeySetIsMutable');
    @PGPKeySetNeedsCommit := GetProcAddress (DLLHandle, 'PGPKeySetNeedsCommit');
    @PGPAddKeys := GetProcAddress (DLLHandle, 'PGPAddKeys');
    @PGPRemoveKeys := GetProcAddress (DLLHandle, 'PGPRemoveKeys');
    @PGPDisableKey := GetProcAddress (DLLHandle, 'PGPDisableKey');
    @PGPEnableKey := GetProcAddress (DLLHandle, 'PGPEnableKey');
    PGPChangeSubKeyPassphraseProcPtr := GetProcAddress (DLLHandle, 'PGPChangeSubKeyPassphrase');
    @PGPRemoveSubKey := GetProcAddress (DLLHandle, 'PGPRemoveSubKey');
    @PGPRemoveUserID := GetProcAddress (DLLHandle, 'PGPRemoveUserID');
    @PGPSetPrimaryUserID := GetProcAddress (DLLHandle, 'PGPSetPrimaryUserID');
    @PGPGetSigCertifierKey := GetProcAddress (DLLHandle, 'PGPGetSigCertifierKey');
    @PGPRemoveSig := GetProcAddress (DLLHandle, 'PGPRemoveSig');
    @PGPCountAdditionalRecipientRequests := GetProcAddress (DLLHandle, 'PGPCountAdditionalRecipientRequests');
    @PGPGetIndexedAdditionalRecipientRequestKey := GetProcAddress (DLLHandle, 'PGPGetIndexedAdditionalRecipientRequestKey');
    PGPPassphraseIsValidProcPtr := GetProcAddress (DLLHandle, 'PGPPassphraseIsValid');
    PGPGenerateKeyProcPtr := GetProcAddress (DLLHandle, 'PGPGenerateKey');
    PGPGenerateSubKeyProcPtr := GetProcAddress (DLLHandle, 'PGPGenerateSubKey');
    PGPGetKeyEntropyNeededProcPtr := GetProcAddress (DLLHandle, 'PGPGetKeyEntropyNeeded');
    PGPExportKeySetProcPtr := GetProcAddress (DLLHandle, 'PGPExportKeySet');
    PGPImportKeySetProcPtr := GetProcAddress (DLLHandle, 'PGPImportKeySet');
    PGPSignUserIDProcPtr := GetProcAddress (DLLHandle, 'PGPSignUserID');
    PGPAddUserIDProcPtr := GetProcAddress (DLLHandle, 'PGPAddUserID');
    PGPRevokeSigProcPtr := GetProcAddress (DLLHandle, 'PGPRevokeSig');
    PGPRevokeKeyProcPtr := GetProcAddress (DLLHandle, 'PGPRevokeKey');
    PGPRevokeSubKeyProcPtr := GetProcAddress (DLLHandle, 'PGPRevokeSubKey');
    @PGPSetKeyTrust := GetProcAddress (DLLHandle, 'PGPSetKeyTrust');
    PGPSetKeyAxiomaticProcPtr := GetProcAddress (DLLHandle, 'PGPSetKeyAxiomatic');
    @PGPUnsetKeyAxiomatic := GetProcAddress (DLLHandle, 'PGPUnsetKeyAxiomatic');
    @PGPGetKeyBoolean := GetProcAddress (DLLHandle, 'PGPGetKeyBoolean');
    @PGPGetKeyNumber := GetProcAddress (DLLHandle, 'PGPGetKeyNumber');
    @PGPGetKeyPropertyBuffer := GetProcAddress (DLLHandle, 'PGPGetKeyPropertyBuffer');
    @PGPGetKeyTime := GetProcAddress (DLLHandle, 'PGPGetKeyTime');
    @PGPGetSubKeyBoolean := GetProcAddress (DLLHandle, 'PGPGetSubKeyBoolean');
    @PGPGetSubKeyNumber := GetProcAddress (DLLHandle, 'PGPGetSubKeyNumber');
    @PGPGetSubKeyPropertyBuffer := GetProcAddress (DLLHandle, 'PGPGetSubKeyPropertyBuffer');
    @PGPGetSubKeyTime := GetProcAddress (DLLHandle, 'PGPGetSubKeyTime');
    @PGPGetUserIDNumber := GetProcAddress (DLLHandle, 'PGPGetUserIDNumber');
    @PGPGetUserIDStringBuffer := GetProcAddress (DLLHandle, 'PGPGetUserIDStringBuffer');
    @PGPGetSigBoolean := GetProcAddress (DLLHandle, 'PGPGetSigBoolean');
    @PGPGetSigNumber := GetProcAddress (DLLHandle, 'PGPGetSigNumber');
    @PGPGetKeyIDOfCertifier := GetProcAddress (DLLHandle, 'PGPGetKeyIDOfCertifier');
    @PGPGetSigTime := GetProcAddress (DLLHandle, 'PGPGetSigTime');
    @PGPGetHashAlgUsed := GetProcAddress (DLLHandle, 'PGPGetHashAlgUsed');
    @PGPGetPrimaryUserID := GetProcAddress (DLLHandle, 'PGPGetPrimaryUserID');
    @PGPGetPrimaryUserIDNameBuffer := GetProcAddress (DLLHandle, 'PGPGetPrimaryUserIDNameBuffer');
    @PGPGetPrimaryUserIDValidity := GetProcAddress (DLLHandle, 'PGPGetPrimaryUserIDValidity');
    @PGPCompareKeys := GetProcAddress (DLLHandle, 'PGPCompareKeys');
    @PGPCompareUserIDStrings := GetProcAddress (DLLHandle, 'PGPCompareUserIDStrings');
    @PGPOrderKeySet := GetProcAddress (DLLHandle, 'PGPOrderKeySet');
    @PGPIncKeyListRefCount := GetProcAddress (DLLHandle, 'PGPIncKeyListRefCount');
    @PGPFreeKeyList := GetProcAddress (DLLHandle, 'PGPFreeKeyList');
    @PGPNewKeyIter := GetProcAddress (DLLHandle, 'PGPNewKeyIter');
    @PGPCopyKeyIter := GetProcAddress (DLLHandle, 'PGPCopyKeyIter');
    @PGPFreeKeyIter := GetProcAddress (DLLHandle, 'PGPFreeKeyIter');
    @PGPKeyIterIndex := GetProcAddress (DLLHandle, 'PGPKeyIterIndex');
    @PGPKeyIterRewind := GetProcAddress (DLLHandle, 'PGPKeyIterRewind');
    @PGPKeyIterSeek := GetProcAddress (DLLHandle, 'PGPKeyIterSeek');
    @PGPKeyIterMove := GetProcAddress (DLLHandle, 'PGPKeyIterMove');
    @PGPKeyIterNext := GetProcAddress (DLLHandle, 'PGPKeyIterNext');
    @PGPKeyIterPrev := GetProcAddress (DLLHandle, 'PGPKeyIterPrev');
    @PGPKeyIterKey := GetProcAddress (DLLHandle, 'PGPKeyIterKey');
    @PGPKeyIterSubKey := GetProcAddress (DLLHandle, 'PGPKeyIterSubKey');
    @PGPKeyIterUserID := GetProcAddress (DLLHandle, 'PGPKeyIterUserID');
    @PGPKeyIterSig := GetProcAddress (DLLHandle, 'PGPKeyIterSig');
    @PGPKeyIterNextSubKey := GetProcAddress (DLLHandle, 'PGPKeyIterNextSubKey');
    @PGPKeyIterPrevSubKey := GetProcAddress (DLLHandle, 'PGPKeyIterPrevSubKey');
    @PGPKeyIterRewindSubKey := GetProcAddress (DLLHandle, 'PGPKeyIterRewindSubKey');
    @PGPKeyIterNextUserID := GetProcAddress (DLLHandle, 'PGPKeyIterNextUserID');
    @PGPKeyIterPrevUserID := GetProcAddress (DLLHandle, 'PGPKeyIterPrevUserID');
    @PGPKeyIterRewindUserID := GetProcAddress (DLLHandle, 'PGPKeyIterRewindUserID');
    @PGPKeyIterNextUIDSig := GetProcAddress (DLLHandle, 'PGPKeyIterNextUIDSig');
    @PGPKeyIterPrevUIDSig := GetProcAddress (DLLHandle, 'PGPKeyIterPrevUIDSig');
    @PGPKeyIterRewindUIDSig := GetProcAddress (DLLHandle, 'PGPKeyIterRewindUIDSig');
    @PGPGetDefaultPrivateKey := GetProcAddress (DLLHandle, 'PGPGetDefaultPrivateKey');
    @PGPSetDefaultPrivateKey := GetProcAddress (DLLHandle, 'PGPSetDefaultPrivateKey');
    @PGPSetKeyUserVal := GetProcAddress (DLLHandle, 'PGPSetKeyUserVal');
    @PGPSetUserIDUserVal := GetProcAddress (DLLHandle, 'PGPSetUserIDUserVal');
    @PGPSetSubKeyUserVal := GetProcAddress (DLLHandle, 'PGPSetSubKeyUserVal');
    @PGPSetSigUserVal := GetProcAddress (DLLHandle, 'PGPSetSigUserVal');
    @PGPGetKeyUserVal := GetProcAddress (DLLHandle, 'PGPGetKeyUserVal');
    @PGPGetUserIDUserVal := GetProcAddress (DLLHandle, 'PGPGetUserIDUserVal');
    @PGPGetSubKeyUserVal := GetProcAddress (DLLHandle, 'PGPGetSubKeyUserVal');
    @PGPGetSigUserVal := GetProcAddress (DLLHandle, 'PGPGetSigUserVal');
    @PGPGetKeyIDFromString := GetProcAddress (DLLHandle, 'PGPGetKeyIDFromString');
    @PGPGetKeyIDFromKey := GetProcAddress (DLLHandle, 'PGPGetKeyIDFromKey');
    @PGPGetKeyIDFromSubKey := GetProcAddress (DLLHandle, 'PGPGetKeyIDFromSubKey');
    @PGPGetKeyIDString := GetProcAddress (DLLHandle, 'PGPGetKeyIDString');
    @PGPExportKeyID := GetProcAddress (DLLHandle, 'PGPExportKeyID');
    @PGPImportKeyID := GetProcAddress (DLLHandle, 'PGPImportKeyID');
    @PGPCompareKeyIDs := GetProcAddress (DLLHandle, 'PGPCompareKeyIDs');
    @PGPGetKeyListContext := GetProcAddress (DLLHandle, 'PGPGetKeyListContext');
    @PGPGetKeySetContext := GetProcAddress (DLLHandle, 'PGPGetKeySetContext');
    @PGPGetKeyIterContext := GetProcAddress (DLLHandle, 'PGPGetKeyIterContext');
    @PGPGetKeyContext := GetProcAddress (DLLHandle, 'PGPGetKeyContext');
    @PGPGetSubKeyContext := GetProcAddress (DLLHandle, 'PGPGetSubKeyContext');
    @PGPGetUserIDContext := GetProcAddress (DLLHandle, 'PGPGetUserIDContext');
    @PGPNewSymmetricCipherContext := GetProcAddress (DLLHandle, 'PGPNewSymmetricCipherContext');
    @PGPFreeSymmetricCipherContext := GetProcAddress (DLLHandle, 'PGPFreeSymmetricCipherContext');
    @PGPCopySymmetricCipherContext := GetProcAddress (DLLHandle, 'PGPCopySymmetricCipherContext');
    @PGPInitSymmetricCipher := GetProcAddress (DLLHandle, 'PGPInitSymmetricCipher');
    @PGPWipeSymmetricCipher := GetProcAddress (DLLHandle, 'PGPWipeSymmetricCipher');
    @PGPWashSymmetricCipher := GetProcAddress (DLLHandle, 'PGPWashSymmetricCipher');
    @PGPSymmetricCipherEncrypt := GetProcAddress (DLLHandle, 'PGPSymmetricCipherEncrypt');
    @PGPSymmetricCipherDecrypt := GetProcAddress (DLLHandle, 'PGPSymmetricCipherDecrypt');
    @PGPGetSymmetricCipherSizes := GetProcAddress (DLLHandle, 'PGPGetSymmetricCipherSizes');
    @PGPNewCFBContext := GetProcAddress (DLLHandle, 'PGPNewCFBContext');
    @PGPFreeCFBContext := GetProcAddress (DLLHandle, 'PGPFreeCFBContext');
    @PGPCopyCFBContext := GetProcAddress (DLLHandle, 'PGPCopyCFBContext');
    @PGPInitCFB := GetProcAddress (DLLHandle, 'PGPInitCFB');
    @PGPCFBEncrypt := GetProcAddress (DLLHandle, 'PGPCFBEncrypt');
    @PGPCFBDecrypt := GetProcAddress (DLLHandle, 'PGPCFBDecrypt');
    @PGPCFBGetSymmetricCipher := GetProcAddress (DLLHandle, 'PGPCFBGetSymmetricCipher');
    @PGPCFBSync := GetProcAddress (DLLHandle, 'PGPCFBSync');
    @PGPCFBGetRandom := GetProcAddress (DLLHandle, 'PGPCFBGetRandom');
    @PGPCFBRandomCycle := GetProcAddress (DLLHandle, 'PGPCFBRandomCycle');
    @PGPCFBRandomWash := GetProcAddress (DLLHandle, 'PGPCFBRandomWash');
    @PGPNewCBCContext := GetProcAddress (DLLHandle, 'PGPNewCBCContext');
    @PGPFreeCBCContext := GetProcAddress (DLLHandle, 'PGPFreeCBCContext');
    @PGPCopyCBCContext := GetProcAddress (DLLHandle, 'PGPCopyCBCContext');
    @PGPInitCBC := GetProcAddress (DLLHandle, 'PGPInitCBC');
    @PGPCBCEncrypt := GetProcAddress (DLLHandle, 'PGPCBCEncrypt');
    @PGPCBCDecrypt := GetProcAddress (DLLHandle, 'PGPCBCDecrypt');
    @PGPCBCGetSymmetricCipher := GetProcAddress (DLLHandle, 'PGPCBCGetSymmetricCipher');
    @PGPNewHashContext := GetProcAddress (DLLHandle, 'PGPNewHashContext');
    @PGPFreeHashContext := GetProcAddress (DLLHandle, 'PGPFreeHashContext');
    @PGPCopyHashContext := GetProcAddress (DLLHandle, 'PGPCopyHashContext');
    @PGPResetHash := GetProcAddress (DLLHandle, 'PGPResetHash');
    @PGPContinueHash := GetProcAddress (DLLHandle, 'PGPContinueHash');
    @PGPFinalizeHash := GetProcAddress (DLLHandle, 'PGPFinalizeHash');
    @PGPGetHashSize := GetProcAddress (DLLHandle, 'PGPGetHashSize');
    PGPEncodeProcPtr := GetProcAddress (DLLHandle, 'PGPEncode');
    PGPDecodeProcPtr := GetProcAddress (DLLHandle, 'PGPDecode');
    @PGPNewOptionList := GetProcAddress (DLLHandle, 'PGPNewOptionList');
    PGPAppendOptionListProcPtr := GetProcAddress (DLLHandle, 'PGPAppendOptionList');
    PGPBuildOptionListProcPtr := GetProcAddress (DLLHandle, 'PGPBuildOptionList');
    @PGPCopyOptionList := GetProcAddress (DLLHandle, 'PGPCopyOptionList');
    @PGPFreeOptionList := GetProcAddress (DLLHandle, 'PGPFreeOptionList');
    PGPAddJobOptionsProcPtr := GetProcAddress (DLLHandle, 'PGPAddJobOptions');
    @PGPOLastOption := GetProcAddress (DLLHandle, 'PGPOLastOption');
    @PGPONullOption := GetProcAddress (DLLHandle, 'PGPONullOption');
    @PGPOInputFile := GetProcAddress (DLLHandle, 'PGPOInputFile');
    @PGPOInputBuffer := GetProcAddress (DLLHandle, 'PGPOInputBuffer');
    @PGPOOutputFile := GetProcAddress (DLLHandle, 'PGPOOutputFile');
    @PGPOOutputBuffer := GetProcAddress (DLLHandle, 'PGPOOutputBuffer');
    @PGPOAllocatedOutputBuffer := GetProcAddress (DLLHandle, 'PGPOAllocatedOutputBuffer');
    @PGPODiscardOutput := GetProcAddress (DLLHandle, 'PGPODiscardOutput');
    @PGPOEncryptToKey := GetProcAddress (DLLHandle, 'PGPOEncryptToKey');
    @PGPOEncryptToKeySet := GetProcAddress (DLLHandle, 'PGPOEncryptToKeySet');
    @PGPOEncryptToUserID := GetProcAddress (DLLHandle, 'PGPOEncryptToUserID');
    PGPOSignWithKeyProcPtr := GetProcAddress (DLLHandle, 'PGPOSignWithKey');
    PGPOConventionalEncryptProcPtr := GetProcAddress (DLLHandle, 'PGPOConventionalEncrypt');
    @PGPOPassphraseBuffer := GetProcAddress (DLLHandle, 'PGPOPassphraseBuffer');
    @PGPOPassphrase := GetProcAddress (DLLHandle, 'PGPOPassphrase');
    @PGPOAskUserForEntropy := GetProcAddress (DLLHandle, 'PGPOAskUserForEntropy');
    @PGPORawPGPInput := GetProcAddress (DLLHandle, 'PGPORawPGPInput');
    @PGPOCompression := GetProcAddress (DLLHandle, 'PGPOCompression');
    @PGPOLocalEncoding := GetProcAddress (DLLHandle, 'PGPOLocalEncoding');
    @PGPOOutputLineEndType := GetProcAddress (DLLHandle, 'PGPOOutputLineEndType');
    @PGPOPGPMIMEEncoding := GetProcAddress (DLLHandle, 'PGPOPGPMIMEEncoding');
    @PGPOOmitMIMEVersion := GetProcAddress (DLLHandle, 'PGPOOmitMIMEVersion');
    PGPODetachedSigProcptr := GetProcAddress (DLLHandle, 'PGPODetachedSig');
    @PGPOCipherAlgorithm := GetProcAddress (DLLHandle, 'PGPOCipherAlgorithm');
    @PGPOHashAlgorithm := GetProcAddress (DLLHandle, 'PGPOHashAlgorithm');
    @PGPOFailBelowValidity := GetProcAddress (DLLHandle, 'PGPOFailBelowValidity');
    @PGPOWarnBelowValidity := GetProcAddress (DLLHandle, 'PGPOWarnBelowValidity');
    @PGPOEventHandler := GetProcAddress (DLLHandle, 'PGPOEventHandler');
    @PGPOSendNullEvents := GetProcAddress (DLLHandle, 'PGPOSendNullEvents');
    @PGPOArmorOutput := GetProcAddress (DLLHandle, 'PGPOArmorOutput');
    @PGPODataIsASCII := GetProcAddress (DLLHandle, 'PGPODataIsASCII');
    @PGPOClearSign := GetProcAddress (DLLHandle, 'PGPOClearSign');
    @PGPOForYourEyesOnly := GetProcAddress (DLLHandle, 'PGPOForYourEyesOnly');
    @PGPOKeySetRef := GetProcAddress (DLLHandle, 'PGPOKeySetRef');
    @PGPOImportKeysTo := GetProcAddress (DLLHandle, 'PGPOImportKeysTo');
    @PGPOSendEventIfKeyFound := GetProcAddress (DLLHandle, 'PGPOSendEventIfKeyFound');
    @PGPOPassThroughIfUnrecognized := GetProcAddress (DLLHandle, 'PGPOPassThroughIfUnrecognized');
    @PGPOKeyGenParams := GetProcAddress (DLLHandle, 'PGPOKeyGenParams');
    @PGPOKeyGenName := GetProcAddress (DLLHandle, 'PGPOKeyGenName');
    @PGPOExpiration := GetProcAddress (DLLHandle, 'PGPOExpiration');
    @PGPOAdditionalRecipientRequestKeySet := GetProcAddress (DLLHandle, 'PGPOAdditionalRecipientRequestKeySet');
    @PGPOKeyGenMasterKey := GetProcAddress (DLLHandle, 'PGPOKeyGenMasterKey');
    @PGPOPreferredAlgorithms := GetProcAddress (DLLHandle, 'PGPOPreferredAlgorithms');
    @PGPOKeyGenFast := GetProcAddress (DLLHandle, 'PGPOKeyGenFast');
    @PGPOCommentString := GetProcAddress (DLLHandle, 'PGPOCommentString');
    @PGPOVersionString := GetProcAddress (DLLHandle, 'PGPOVersionString');
    @PGPOSigRegularExpression := GetProcAddress (DLLHandle, 'PGPOSigRegularExpression');
    @PGPOExportPrivateKeys := GetProcAddress (DLLHandle, 'PGPOExportPrivateKeys');
    @PGPOExportable := GetProcAddress (DLLHandle, 'PGPOExportable');
    @PGPOSigTrust := GetProcAddress (DLLHandle, 'PGPOSigTrust');
    @PGPGetErrorString := GetProcAddress (DLLHandle, 'PGPGetErrorString');
    @PGPNewContext := GetProcAddress (DLLHandle, 'PGPNewContext');
    @PGPNewContextCustom := GetProcAddress (DLLHandle, 'PGPNewContextCustom');
    @PGPFreeContext := GetProcAddress (DLLHandle, 'PGPFreeContext');
    @PGPGetContextUserValue := GetProcAddress (DLLHandle, 'PGPGetContextUserValue');
    @PGPSetContextUserValue := GetProcAddress (DLLHandle, 'PGPSetContextUserValue');
    @PGPContextGetRandomBytes := GetProcAddress (DLLHandle, 'PGPContextGetRandomBytes');
    @PGPGetContextMemoryMgr := GetProcAddress (DLLHandle, 'PGPGetContextMemoryMgr');
    @PGPNewData := GetProcAddress (DLLHandle, 'PGPNewData');
    @PGPNewSecureData := GetProcAddress (DLLHandle, 'PGPNewSecureData');
    @PGPFreeData := GetProcAddress (DLLHandle, 'PGPFreeData');
    @PGPCopyFileSpec := GetProcAddress (DLLHandle, 'PGPCopyFileSpec');
    @PGPFreeFileSpec := GetProcAddress (DLLHandle, 'PGPFreeFileSpec');
    @PGPNewFileSpecFromFullPath := GetProcAddress (DLLHandle, 'PGPNewFileSpecFromFullPath');
    @PGPGetFullPathFromFileSpec := GetProcAddress (DLLHandle, 'PGPGetFullPathFromFileSpec');
    @PGPGetTime := GetProcAddress (DLLHandle, 'PGPGetTime');
    @PGPGetStdTimeFromPGPTime := GetProcAddress (DLLHandle, 'PGPGetStdTimeFromPGPTime');
    @PGPGetPGPTimeFromStdTime := GetProcAddress (DLLHandle, 'PGPGetPGPTimeFromStdTime');
    @PGPGetYMDFromPGPTime := GetProcAddress (DLLHandle, 'PGPGetYMDFromPGPTime');
    @PGPsdkInit := GetProcAddress (DLLHandle, 'PGPsdkInit');
    @PGPsdkCleanup := GetProcAddress (DLLHandle, 'PGPsdkCleanup');
    @PGPGetSDKVersion := GetProcAddress (DLLHandle, 'PGPGetSDKVersion');
    if (not assigned (PGPGetSDKVersion)) then begin
      @PGPGetSDKVersion := GetProcAddress (DLLHandle, 'PGPGetPGPsdkVersion');
    end;
    @PGPGetSDKString := GetProcAddress (DLLHandle, 'PGPGetSDKString');
    if (not assigned (PGPGetSDKString)) then begin
      PGPGetSDKString := GetProcAddress (DLLHandle, 'PGPGetPGPsdkVersionString');
    end;
    @PGPGetFeatureFlags := GetProcAddress (DLLHandle, 'PGPGetFeatureFlags');
    @PGPCountPublicKeyAlgorithms := GetProcAddress (DLLHandle, 'PGPCountPublicKeyAlgorithms');
    @PGPGetIndexedPublicKeyAlgorithmInfo := GetProcAddress (DLLHandle, 'PGPGetIndexedPublicKeyAlgorithmInfo');
    @PGPCountSymmetricCiphers := GetProcAddress (DLLHandle, 'PGPCountSymmetricCiphers');
    @PGPGetIndexedSymmetricCipherInfo := GetProcAddress (DLLHandle, 'PGPGetIndexedSymmetricCipherInfo');
    @PGPsdkLoadPrefs := GetProcAddress (DLLHandle, 'PGPsdkLoadPrefs');
    @PGPsdkLoadDefaultPrefs := GetProcAddress (DLLHandle, 'PGPsdkLoadDefaultPrefs');
    @PGPsdkSavePrefs := GetProcAddress (DLLHandle, 'PGPsdkSavePrefs');
    @PGPsdkPrefSetFileSpec := GetProcAddress (DLLHandle, 'PGPsdkPrefSetFileSpec');
    @PGPsdkPrefGetFileSpec := GetProcAddress (DLLHandle, 'PGPsdkPrefGetFileSpec');
    @PGPsdkPrefSetData := GetProcAddress (DLLHandle, 'PGPsdkPrefSetData');
    @PGPsdkPrefGetData := GetProcAddress (DLLHandle, 'PGPsdkPrefGetData');
    @PGPKeyServerInit := GetProcAddress (DLLHandle, 'PGPKeyServerInit');
    @PGPKeyServerCleanup := GetProcAddress (DLLHandle, 'PGPKeyServerCleanup');
    @PGPKeyServerOpen := GetProcAddress (DLLHandle, 'PGPKeyServerOpen');
    @PGPKeyServerClose := GetProcAddress (DLLHandle, 'PGPKeyServerClose');
    @PGPNewKeyServerFromURL := GetProcAddress (DLLHandle, 'PGPNewKeyServerFromURL');
    @PGPFreeKeyServer := GetProcAddress (DLLHandle, 'PGPFreeKeyServer');
    @PGPQueryKeyServer := GetProcAddress (DLLHandle, 'PGPQueryKeyServer');
    @PGPUploadToKeyServer := GetProcAddress (DLLHandle, 'PGPUploadToKeyServer');
    @PGPDeleteFromKeyServer := GetProcAddress (DLLHandle, 'PGPDeleteFromKeyServer');
    @PGPDisableFromKeyServer := GetProcAddress (DLLHandle, 'PGPDisableFromKeyServer');
    @PGPSetKeyServerEventHandler := GetProcAddress (DLLHandle, 'PGPSetKeyServerEventHandler');
    @PGPGetLastKeyServerErrorString := GetProcAddress (DLLHandle, 'PGPGetLastKeyServerErrorString');
    @PGPNewServerMonitor := GetProcAddress (DLLHandle, 'PGPNewServerMonitor');
    @PGPFreeServerMonitor := GetProcAddress (DLLHandle, 'PGPFreeServerMonitor');

    S := PGPMissingFunctions (DLLHandle);
    if (Length (S) > 0) then begin
      PGPDLLError := DLLName + ': Funktionen fehlen: ' + S;
      DebOut (DebPrefix + PGPDLLError);
      FreeLibrary (DLLHandle);
      DLLHandle := 0;
      PGPDLLloaded := false;
    end else begin
      PGPDLLError := '';
    end;

  end else begin

    DebOut (DebPrefix + 'PGP nicht geladen.');

  end;

  result := PGPDLLloaded;

end;


procedure   FreePGPDLL;
begin
  if (PGPDLLloaded) then begin
    FreeLibrary (DLLHandle);
    PGPDLLloaded := false;
  end;
  DLLHandle := 0;
end;


function    PGPDescribeEvent (etype: integer): string;
begin
  case etype of
    kPGPEvent_NullEvent: result := 'Nothing happened';
    kPGPEvent_InitialEvent: result := 'Initial event';
    kPGPEvent_FinalEvent: result := 'Final event';
    kPGPEvent_ErrorEvent: result := 'An error occurred';
    kPGPEvent_WarningEvent: result := 'Warning event';
    kPGPEvent_EntropyEvent: result := 'More entropy is needed';
    kPGPEvent_PassphraseEvent: result := 'A passphrase is needed';
    kPGPEvent_InsertKeyEvent: result := 'Smart card must be inserted';
    kPGPEvent_AnalyzeEvent: result := 'Initial analysis event, before any output';
    kPGPEvent_RecipientsEvent: result := 'Recipient list report, before any output';
    kPGPEvent_KeyFoundEvent: result := 'Key packet found';
    kPGPEvent_OutputEvent: result := 'Output specification needed';
    kPGPEvent_SignatureEvent: result := 'Signature status report';
    kPGPEvent_BeginLexEvent: result := 'Initial event per lexical unit';
    kPGPEvent_EndLexEvent: result := 'Final event per lexical unit';
    kPGPEvent_RecursionEvent: result := 'Notification of recursive job creation';
    kPGPEvent_DetachedSignatureEvent: result := 'Need input for verification of detached signature';
    kPGPEvent_KeyGenEvent: result := 'Key generation progress';
    kPGPEvent_KeyServerEvent: result := 'Key Server progress';
    kPGPEvent_KeyServerSignEvent: result := 'Key Server passphrase';
  else
    result := 'Unknown Event ' + inttostr (etype);
  end;
end;


procedure InitkPGPKeyProp;
begin

  if (kPGPsdkAPIVersion >= $03000000) then begin


    kPGPKeyPropFingerprint := 1;
    kPGPKeyPropPreferredAlgorithms := 2;
    kPGPKeyPropThirdPartyRevocationKeyID := 3;


    kPGPKeyPropAlgID := 20;
    kPGPKeyPropBits := 21;
    kPGPKeyPropTrust := 22;
    kPGPKeyPropValidity := 23;
    kPGPKeyPropLockingAlgID := 24;
    kPGPKeyPropLockingBits := 25;
    kPGPKeyPropFlags := 26;

    kPGPKeyPropCreation := 40;
    kPGPKeyPropExpiration := 41;

    kPGPKeyPropIsSecret := 60;
    kPGPKeyPropIsAxiomatic := 61;
    kPGPKeyPropIsRevoked := 62;
    kPGPKeyPropIsDisabled := 63;
    kPGPKeyPropIsNotCorrupt := 64;
    kPGPKeyPropIsExpired := 65;
    kPGPKeyPropNeedsPassphrase := 66;
    kPGPKeyPropHasUnverifiedRevocation := 67;
    kPGPKeyPropCanEncrypt := 68;
    kPGPKeyPropCanDecrypt := 69;
    kPGPKeyPropCanSign := 70;
    kPGPKeyPropCanVerify := 71;
    kPGPKeyPropIsEncryptionKey := 72;
    kPGPKeyPropIsSigningKey := 73;
    kPGPKeyPropIsSecretShared := 74;
    kPGPKeyPropIsRevocable := 75;
    kPGPKeyPropHasThirdPartyRevocation := 76;

  end else if (kPGPsdkAPIVersion >= $02000000) then begin


    kPGPKeyPropFingerprint := 11;
    kPGPKeyPropPreferredAlgorithms := 12;
    kPGPKeyPropThirdPartyRevocationKeyID := -1;

    kPGPKeyPropAlgID := 20;
    kPGPKeyPropBits := 21;
    kPGPKeyPropTrust := 22;
    kPGPKeyPropValidity := 23;

    kPGPKeyPropCreation := 30;
    kPGPKeyPropExpiration := 31;

    kPGPKeyPropIsSecret := 40;
    kPGPKeyPropIsAxiomatic := 41;
    kPGPKeyPropIsRevoked := 42;
    kPGPKeyPropIsDisabled := 43;
    kPGPKeyPropIsNotCorrupt := 44;
    kPGPKeyPropIsExpired := 45;
    kPGPKeyPropNeedsPassphrase := 46;
    kPGPKeyPropCanSign := 47;
    kPGPKeyPropCanEncrypt := 48;
    kPGPKeyPropHasUnverifiedRevocation := 49;

  end;

end;


procedure InitUserIDProp;
begin

  if (kPGPsdkAPIVersion >= $03000000) then begin


    kPGPUserIDPropName := 80;
    kPGPUserIDPropAttributeData := 81;

    kPGPUserIDPropValidity := 100;
    kPGPUserIDPropConfidence := 101;
    kPGPUserIDPropAttributeType := 102;

    kPGPUserIDPropIsAttribute := 110;

  end else if (kPGPsdkAPIVersion >= $02000000) then begin


    kPGPUserIDPropName := 50;

    kPGPUserIDPropValidity := 60;
    kPGPUserIDPropConfidence := 61;

  end;

end;


procedure InitSigProp;

begin

  if (kPGPsdkAPIVersion >= $03000000) then begin

    kPGPSigPropKeyID := 120;
    kPGPSigPropX509Certificate := 121;

    kPGPSigPropAlgID := 140;
    kPGPSigPropTrustLevel := 141;
    kPGPSigPropTrustValue := 142;

    kPGPSigPropCreation := 160;
    kPGPSigPropExpiration := 161;

    kPGPSigPropIsRevoked := 180;
    kPGPSigPropIsNotCorrupt := 181;
    kPGPSigPropIsTried := 182;
    kPGPSigPropIsVerified := 183;
    kPGPSigPropIsMySig := 184;
    kPGPSigPropIsExportable := 185;
    kPGPSigPropHasUnverifiedRevocation := 186;
    kPGPSigPropIsExpired := 187;
    kPGPSigPropIsX509 := 188;

  end else if (kPGPsdkAPIVersion >= $02000000) then begin

    kPGPSigPropKeyID := 90;

    kPGPSigPropAlgID := 100;
    kPGPSigPropTrustLevel := 101;
    kPGPSigPropTrustValue := 102;

    kPGPSigPropCreation := 110;
    kPGPSigPropExpiration := 111;

    kPGPSigPropIsRevoked := 120;
    kPGPSigPropIsNotCorrupt := 121;
    kPGPSigPropIsTried := 122;
    kPGPSigPropIsVerified := 123;
    kPGPSigPropIsMySig := 124;
    kPGPSigPropIsExportable := 125;
    kPGPSigPropHasUnverifiedRevocation := 126;

  end;

end;


{$IFOPT O+}
  {$DEFINE OPTIMIZATION}
{$ELSE}
  {$UNDEF OPTIMIZATION}
{$ENDIF}

{$IFOPT W+}
  {$DEFINE STACKFRAMES}
{$ELSE}
  {$UNDEF STACKFRAMES}
{$ENDIF}

{$O-}
{$W+}


function PGPEncode (context: pPGPContext; Args: array of pPGPOptionsList): PGPError;
var
  i: integer;
  x: pointer;
begin
  DebOut ('PgpApiU.PGPEncode: begin...');
  x := pointer (-1);
  asm
    push x;
  end;
  for i := high (args) downto low (args) do begin
    x := Args[i];
    asm
      push x;
    end;
  end;
  asm
    push context;
    call PGPEncodeprocPtr
    mov result, eax;
    pop context;
  end;
  for i := high (args) downto low (args) do begin
    asm
      pop x;
    end;
  end;
  asm
    pop x;
  end;
  DebOut ('PgpApiU.PGPEncode: end.');
end;


function PGPDecode (context: pPGPContext; Args: array of pPGPOptionsList): PGPError;
var
  i: integer;
  x: pointer;
begin
  DebOut ('PgpApiU.PGPDecode: begin...');
  x := pointer (-1);
  asm
    push x;
  end;
  for i := high (args) downto low (args) do begin
    x := Args[i];
    asm
      push x;
    end;
  end;
  asm
    push context;
    call PGPDecodeprocPtr
    mov result, eax;
    pop context;
  end;
  for i := high (args) downto low (args) do begin
    asm
      pop x;
    end;
  end;
  asm
    pop x;
  end;
  DebOut ('PgpApiU.PGPDecode: end.');
end;


function PGPGenerateKey (context: pPGPContext; var key: pPGPKey; Args: array of pPGPOptionsList): PGPError;
var
  i: integer;
  x: pointer;
begin
  DebOut ('PgpApiU.PGPGenerateKey: begin...');
  x := pointer (-1);
  asm
    push x;
  end;
  for i := high (args) downto low (args) do begin
    x := Args[i];
    asm
      push x;
    end;
  end;
  asm
    push key;
    push context;
    call PGPGenerateKeyProcPtr;
    mov result, eax;
    pop context;
    pop key;
  end;
  for i := high (args) downto low (args) do begin
    asm
      pop x;
    end;
  end;
  asm
    pop x;
  end;
  DebOut ('PgpApiU.PGPGenerateKey: end.');
end;


function PGPGenerateSubKey (context: pPGPContext; var subkey: pPGPSubkey; Args: array of pPGPOptionsList): PGPError;
var
  i: integer;
  x: pointer;
begin
  DebOut ('PgpApiU.PGPGenerateSubKey: begin...');
  x := pointer (-1);
  asm
    push x;
  end;
  for i := high (args) downto low (args) do begin
    x := Args[i];
    asm
      push x;
    end;
  end;
  asm
    push subkey;
    push context;
    call PGPGeneratesubKeyProcPtr;
    mov result, eax;
    pop context;
    pop subkey;
  end;
  for i := high (args) downto low (args) do begin
    x := Args[i];
    asm
      pop x;
    end;
  end;
  asm
    pop x;
  end;
  DebOut ('PgpApiU.PGPGenerateSubKey: end.');
end;


function PGPGetKeyEntropyNeeded (context: pPGPContext; Args: array of pPGPOptionsList): PGPUInt32;
var
  i: integer;
  x: pointer;
begin
  DebOut ('PgpApiU.PGPGetKeyEntropyNeeded: begin...');
  x := pointer (-1);
  asm
    push x;
  end;
  for i := high (args) downto low (args) do begin
    x := Args[i];
    asm
      push x;
    end;
  end;
  asm
    push context;
    call PGPGetKeyEntropyNeededprocPtr;
    mov result, eax;
    pop context;
  end;
  for i := high (args) downto low (args) do begin
    asm
      pop x;
    end;
  end;
  asm
    pop x;
  end;
  DebOut ('PgpApiU.PGPGetKeyEntropyNeeded: end.');
end;


function PGPExportKeySet (keys: pPGPKeySet; Args: array of pPGPOptionsList): PGPError;
var
  i: integer;
  x: pointer;
begin
  DebOut ('PgpApiU.PGPExportKeySet: begin...');
  x := pointer (-1);
  asm
    push x;
  end;
  for i := high (args) downto low (args) do begin
    x := Args[i];
    asm
      push x;
    end;
  end;
  asm
    push keys;
    call PGPExportKeySetProcPtr;
    mov result, eax;
    pop keys;
  end;
  for i := high (args) downto low (args) do begin
    asm
      pop x;
    end;
  end;
  asm
    pop x;
  end;
  DebOut ('PgpApiU.PGPExportKeySet: end.');
end;


function PGPImportKeySet (context: pPGPContext; var keys: pPGPKeyset; Args: array of pPGPOptionsList): PGPError;
var
  i: integer;
  x: pointer;
begin
  DebOut ('PgpApiU.PGPImportKeySet: begin...');
  x := pointer (-1);
  asm
    push x;
  end;
  for i := high (args) downto low (args) do begin
    x := Args[i];
    asm
      push x;
    end;
  end;
  asm
    push keys;
    push context;
    call PGPImportKeySetProcPtr;
    mov result, eax;
    pop context;
    pop keys;
  end;
  for i := high (args) downto low (args) do begin
    asm
      pop x;
    end;
  end;
  asm
    pop x;
  end;
  DebOut ('PgpApiU.PGPImportKeySet: end.');
end;


function PGPSignUserID (userID: pPGPUserID; certifyingKey: pPGPKey; Args: array of pPGPOptionsList): PGPError;
var
  i: integer;
  x: pointer;
begin
  DebOut ('PgpApiU.PGPSignUserID: begin...');
  x := pointer (-1);
  asm
    push x;
  end;
  for i := high (args) downto low (args) do begin
    x := Args[i];
    asm
      push x;
    end;
  end;
  asm
    push CertifyingKey;
    push userID;
    call PGPSignUserIDProcPtr;
    mov result, eax;
    pop userID;
    pop CertifyingKey;
  end;
  for i := high (args) downto low (args) do begin
    asm
      pop x;
    end;
  end;
  asm
    pop x;
  end;
  DebOut ('PgpApiU.PGPSignUserID: end.');
end;


function PGPAddUserID (key: pPGPKey; const userID: PChar; Args: array of pPGPOptionsList): PGPError;
var
  i: integer;
  x: pointer;
begin
  DebOut ('PgpApiU.PGPAddUserID: begin...');
  x := pointer (-1);
  asm
    push x;
  end;
  for i := high (args) downto low (args) do begin
    x := Args[i];
    asm
      push x;
    end;
  end;
  asm
    push userID;
    push key;
    call PGPAddUserIDProcPtr;
    mov result, eax;
    pop key;
    pop userId;
  end;
  for i := high (args) downto low (args) do begin
    asm
      pop x;
    end;
  end;
  asm
    pop x;
  end;
  DebOut ('PgpApiU.PGPAddUserID: end.');
end;


function PGPRevokeSig (cert: pPGPSig; allkeys: pPGPKeySet; Args: array of pPGPOptionsList): PGPError;
var
  i: integer;
  x: pointer;
begin
  DebOut ('PgpApiU.PGPRevokeSig: begin...');
  x := pointer (-1);
  asm
    push x;
  end;
  for i := high (args) downto low (args) do begin
    x := Args[i];
    asm
      push x;
    end;
  end;
  asm
    push allkeys;
    push cert;
    call PGPRevokeSigProcPtr;
    mov result, eax;
    pop cert;
    pop allkeys;
  end;
  for i := high (args) downto low (args) do begin
    asm
      pop x;
    end;
  end;
  asm
    pop x;
  end;
  DebOut ('PgpApiU.PGPRevokeSig: end.');
end;


function PGPRevokeKey (key: pPGPKey; Args: array of pPGPOptionsList): PGPError;
var
  i: integer;
  x: pointer;
begin
  DebOut ('PgpApiU.PGPRevokeKey: begin...');
  x := pointer (-1);
  asm
    push x;
  end;
  for i := high (args) downto low (args) do begin
    x := Args[i];
    asm
      push x;
    end;
  end;
  asm
    push key;
    call PGPRevokeKeyProcPtr;
    mov result, eax;
    pop key;
  end;
  for i := high (args) downto low (args) do begin
    asm
      pop x;
    end;
  end;
  asm
    pop x;
  end;
  DebOut ('PgpApiU.PGPRevokeKey: end.');
end;


function PGPRevokeSubKey (subkey: pPGPSubKey; Args: array of pPGPOptionsList): PGPError;
var
  i: integer;
  x: pointer;
begin
  DebOut ('PgpApiU.PGPRevokeSubKey: begin...');
  x := pointer (-1);
  asm
    push x;
  end;
  for i := high (args) downto low (args) do begin
    x := Args[i];
    asm
      push x;
    end;
  end;
  asm
    push subkey;
    call PGPRevokeSubKeyProcPtr;
    mov result, eax;
    pop subkey;
  end;
  for i := high (args) downto low (args) do begin
    asm
      pop x;
    end;
  end;
  asm
    pop x;
  end;
  DebOut ('PgpApiU.PGPRevokeSubKey: end.');
end;


function PGPChangeSubKeyPassphrase (subkey: pPGPSubKey; Args: array of pPGPOptionsList): PGPError;
var
  i: integer;
  x: pointer;
begin
  DebOut ('PgpApiU.PGPChangeSubKeyPassphrase: begin...');
  x := pointer (-1);
  asm
    push x;
  end;
  for i := high (args) downto low (args) do begin
    x := Args[i];
    asm
      push x;
    end;
  end;
  asm
    push subkey;
    call PGPChangeSubKeyPassphraseProcPtr;
    mov result, eax;
    pop subkey;
  end;
  for i := high (args) downto low (args) do begin
    asm
      pop x;
    end;
  end;
  asm
    pop x;
  end;
  DebOut ('PgpApiU.PGPChangeSubKeyPassphrase: end.');
end;


function PGPPassphraseIsValid (key: pPGPKey; Args: array of pPGPOptionsList): PGPBoolean;
var
  i: integer;
  x: pointer;
begin
  DebOut ('PgpApiU.PGPPassphraseIsValid: begin...');
  x := pointer (-1);
  asm
    push x;
  end;
  for i := high (args) downto low (args) do begin
    x := Args[i];
    asm
      push x;
    end;
  end;
  asm
    push key;
    call PGPPassphraseIsValidProcPtr;
    mov result, al;
    pop key;
  end;
  for i := high (args) downto low (args) do begin
    asm
      pop x;
    end;
  end;
  asm
    pop x;
  end;
  DebOut ('PgpApiU.PGPPassphraseIsValid: end.');
end;


function PGPSetKeyAxiomatic (key: pPGPKey; Args: array of pPGPOptionsList): PGPError;
var
  i: integer;
  x: pointer;
begin
  DebOut ('PgpApiU.PGPSetKeyAxiomatic: begin...');
  x := pointer (-1);
  asm
    push x;
  end;
  for i := high (args) downto low (args) do begin
    x := Args[i];
    asm
      push x;
    end;
  end;
  asm
    push key;
    call PGPSetKeyAxiomaticProcPtr;
    mov result, eax;
    pop key;
  end;
  for i := high (args) downto low (args) do begin
    asm
      pop x;
    end;
  end;
  asm
    pop x;
  end;
  DebOut ('PgpApiU.PGPSetKeyAxiomatic: end.');
end;


function PGPNewPrivateKeyContext (privateKeyRef: pPGPKey; messageFormat: PGPPublicKeyMessageFormat;
                                  var outRef: pPGPPrivateKeyContext; Args: array of pPGPOptionsList): PGPError;
var
  i: integer;
  x: pointer;
begin
  DebOut ('PgpApiU.PGPNewPrivateKeyContext: begin...');
  x := pointer (-1);
  asm
    push x;
  end;
  for i := high (args) downto low (args) do begin
    x := Args[i];
    asm
      push x;
    end;
  end;
  asm
    push outRef;
    push messageFormat;
    push privateKeyRef;
    call PGPNewPrivateKeyContextProcPtr;
    mov result, eax;
    pop privateKeyRef;
    pop messageFormat;
    pop outRef;
  end;
  for i := high (args) downto low (args) do begin
    asm
      pop x;
    end;
  end;
  asm
    pop x;
  end;
  DebOut ('PgpApiU.PGPNewPrivateKeyContext: end.');
end;


function PGPAppendOptionList (optionList: pPGPOptionsList; Args: array of pPGPOptionsList): PGPError;
var
  i: integer;
  x: pointer;
begin
  DebOut ('PgpApiU.PGPAppendOptionList: begin...');
  x := pointer (-1);
  asm
    push x;
  end;
  for i := high (args) downto low (args) do begin
    x := Args[i];
    asm
      push x;
    end;
  end;
  asm
    push optionList;
    call PGPAppendOptionListProcPtr;
    mov result, eax;
    pop optionList;
  end;
  for i := high (args) downto low (args) do begin
    asm
      pop x;
    end;
  end;
  asm
    pop x;
  end;
  DebOut ('PgpApiU.PGPAppendOptionList: end.');
end;


function PGPBuildOptionList (context: pPGPContext; var outList: pPGPOptionsList; Args: array of pPGPOptionsList): PGPError;
var
  i: integer;
  x: pointer;
begin
  DebOut ('PgpApiU.PGPBuildOptionList: begin...');
  x := pointer (-1);
  asm
    push x;
  end;
  for i := high (args) downto low (args) do begin
    x := Args[i];
    asm
      push x;
    end;
  end;
  asm
    push outlist;
    push context;
    call PGPBuildOptionListProcPtr;
    mov result, eax;
    pop context;
    pop outlist;
  end;
  for i := high (args) downto low (args) do begin
    x := Args[i];
    asm
      pop x;
    end;
  end;
  asm
    pop x;
  end;
  DebOut ('PgpApiU.PGPBuildOptionList: end.');
end;


function PGPOSignWithKey (context: pPGPContext; keyRef: pPGPKey; Args: array of pPGPOptionsList): pPGPOptionsList;
var
  i: integer;
  x: pointer;
begin
  DebOut ('PgpApiU.PGPOSignWithKey: begin...');
  x := pointer (-1);
  asm
    push x;
  end;
  for i := high (args) downto low (args) do begin
    x := Args[i];
    asm
      push x;
    end;
  end;
  asm
    push keyRef;
    push context;
    call PGPOSignWithKeyProcPtr;
    mov result, eax;
    pop context;
    pop keyRef;
  end;
  for i := high (args) downto low (args) do begin
    asm
      pop x;
    end;
  end;
  asm
    pop x;
  end;
  DebOut ('PgpApiU.PGPOSignWithKey: end.');
end;


function PGPOConventionalEncrypt (context: pPGPContext; Args: array of pPGPOptionsList): pPGPOptionsList;
var
  i: integer;
  x: pointer;
begin
  DebOut ('PgpApiU.PGPOConventionalEncrypt: begin...');
  x := pointer (-1);
  asm
    push x;
  end;
  for i := high (args) downto low (args) do begin
    x := Args[i];
    asm
      push x;
    end;
  end;
  asm
    push context;
    call PGPOConventionalEncryptProcPtr;
    mov result, eax;
    pop context;
  end;
  for i := high (args) downto low (args) do begin
    asm
      pop x;
    end;
  end;
  asm
    pop x;
  end;
  DebOut ('PgpApiU.PGPOConventionalEncrypt: end.');
end;


function PGPODetachedSig (context: pPGPContext; Args: array of pPGPOptionsList): pPGPOptionsList;
var
  i: integer;
  x: pointer;
begin
  DebOut ('PgpApiU.PGPODetachedSig: begin...');
  x := pointer (-1);
  asm
    push x;
  end;
  for i := high (args) downto low (args) do begin
    x := Args[i];
    asm
      push x;
    end;
  end;
  asm
    push context;
    call PGPODetachedSigProcPtr;
    mov result, eax;
    pop context;
  end;
  for i := high (args) downto low (args) do begin
    asm
      pop x;
    end;
  end;
  asm
    pop x;
  end;
  DebOut ('PgpApiU.PGPODetachedSig: end.');
end;


function PGPAddJobOptions (job: pPGPJob; Args: array of pPGPOptionsList): PGPError;
var
  i: integer;
  x: pointer;
begin
  DebOut ('PgpApiU.PGPAddJobOptions: begin...');
  x := pointer (-1);
  asm
    push x;
  end;
  for i := high (args) downto low (args) do begin
    x := Args[i];
    asm
      push x;
    end;
  end;
  asm
    push job;
    call PGPAddJobOptionsprocPtr;
    mov result, eax;
    pop job;
  end;
  for i := high (args) downto low (args) do begin
    asm
      pop x;
    end;
  end;
  asm
    pop x;
  end;
  DebOut ('PgpApiU.PGPAddJobOptions: begin...');
end;


{$IFDEF OPTIMIZATION}
  {$O+}
{$ELSE}
  {$O-}
{$ENDIF}

{$IFDEF STACKFRAMES}
  {$W+}
{$ELSE}
  {$W-}
{$ENDIF}


initialization

  DebOut ('PGPApiU.initialization: begin...');
  InitPGPDLL;
  LoadPGPDLL;
  DebOut ('PGPApiU.initialization: end.');

finalization

  FreePGPDLL;

end.

