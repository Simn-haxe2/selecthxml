package selecthxml;

class TypedResult<T:Xml> implements Dynamic
{
	var __x_m_l__:Xml;
	
	public function new(xml:Xml)
	{
		__x_m_l__ = xml;
	}
}