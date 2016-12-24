pragma(LDC_no_moduleinfo);


struct Vec2
{
	int x, y;

	void opAddAssign(Vec2 other)
	{
		x += other.x;
		y += other.y;
	}

	Vec2 opAdd(T)(T val) const
	{
		Vec2 r = this;
		r.x += val.x;
		r.y += val.y;
		return r;
	}

	void opSubAssign(Vec2 other)
	{
		x -= other.x;
		y -= other.y;
	}

	Vec2 opSub(T)(T val) const
	{
		Vec2 r = this;
		r.x -= val.x;
		r.y -= val.y;
		return r;
	}

	void opMulAssign(T)(T val)
	{
		x *= val;
		y *= val;
	}

	Vec2 opMul(T)(T val) const
	{
		Vec2 r = this;
		r.x *= val;
		r.y *= val;
		return r;
	}

	void opDivAssign(T)(T val)
	{
		x /= val;
		y /= val;
	}

	Vec2 opDiv(T)(T val) const
	{
		Vec2 r = this;
		r.x /= val;
		r.y /= val;
		return r;
	}
}

auto abs(T)(T val)
{
	if(val < 0)
		return -val;
	else
		return val;
}

