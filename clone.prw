#include 'protheus.ch'

user function ENTRY()
	AddPrivilegeToAllUsers('000001','2')
return nil

/*/{Protheus.doc} AddPrivilegeToAllUsers
	Adiciona privilégio para todos os usuários do sistema
	@author thiago.crash
	@since 19/07/2024
/*/
static function AddPrivilegeToAllUsers(cCod as character,cOwner as character)
	local aArea := GetArea()
	local aUsersCodes as array
	local nX := 0
	local nErro := 0
	Begin Transaction

		aUsersCodes := GetAllUsersCodes()

		for nX := 1 to Len(aUsersCodes)
			nErro += AddPvl(aUsersCodes[nX],AllTrim(cCod),AllTrim(cOwner))
		next nX

		if nErro > 0
			alert("Disarmando a transação. Erros: " + cValToChar(nErro))
			DisarmTransaction()
		else
			FWAlertSucess("Privilégios adicionados!")
		endif

	End Transaction
	RestArea(aArea)
return nil


static function GetAllUsersCodes() as array
	local aCodes := {}

	beginsql alias "CODES"
        SELECT USR_ID FROM SYS_USR
	endsql

	while CODES->(!Eof())
		aAdd(aCodes,AllTrim(CODES->USR_ID))
		DbSkip()
	enddo

	CODES->(DBCloseArea())
return aCodes

static function AddPvl(cUser,cCod,cOwner) as numeric
	local nErro := 0
	local cNome := GetPvlName(cCod)
	local cQuery := ""

	if !UserHasPvl(cUser,cCod)
		if !Empty(cNome)
			cQuery += "insert into sys_rules_usr_rules "
			cQuery += "(user_id,usr_rl_id,usr_rl_codigo,usr_rl_owner) "
			cQuery += "values "
			cQuery += "('"+cUser+"','"+cCod+"','"+cNome+"',"+cOwner+")"
			if TCSQLExec(cQuery) < 0
				alert('Erro no clone' + TcSqlError())
				nErro += 1
			endif
		else
			nErro+=1
		endif
	endif
return nErro

static function GetPvlName(cCod as character) as character
	local cName as character
	cCod := AllTrim(cCod)

	beginsql alias "CODNAME"
        SELECT RL__CODIGO FROM SYS_RULES WHERE RL__ID = %Exp:cCod%
	endsql

	cName = CODNAME->RL__CODIGO
	CODNAME->(DBCloseArea())
return AllTrim(cName)

static function UserHasPvl(cUser as character, cCod as character) as logical
	local lRet := .F.

	beginsql alias "USERCODE"
		SELECT R_E_C_N_O_ from SYS_RULES_USR_RULES WHERE USER_ID = %Exp:cUser% AND USR_RL_ID = %Exp:cCod% AND R_E_C_D_E_L_ = 0
	endsql

	if !Empty(USERCODE->R_E_C_N_O_)
		lRet := .T.
	endif

	USERCODE->(DBCloseArea())

return lRet
