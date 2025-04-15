
bool IsCool(string username)
{
	return 	username=="PURPLExeno"||
			username=="TheCustomerMan"||
			username=="NoahTheLegend"||
			username== "5elfless"||
			
			(isServer()&&isClient()); 					//**should** return true only on localhost
}