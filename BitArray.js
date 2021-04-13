"use strict";

export class BitArray
{
	constructor(size = 8)
	{
		if (size % 8 != 0) throw new Error("Unable to initialize BitArray: 'size' must be a multiple of 8");
		let actualSize = Math.ceil(size / 8);
		this._array = new Uint8Array(actualSize);
	}

	_calculateArrayIndexAndExponent(index)
	{
		let returnData = new Array(2);
		returnData[0] = Math.floor(index / 8);
		returnData[1] =	Math.ceil(index - (8 * returnData[0]));

		return returnData;
	}

	setAll(value = 0)
	{
		if (value > 1) return;
		this._array.fill(value);
	}

	set(index)
	{
		let data = this._calculateArrayIndexAndExponent(index);
		this._array[data[0]] |= Math.pow(2, data[1]);
	}

	unset(index)
	{
		let data = this._calculateArrayIndexAndExponent(index);
		this._array[data[0]] &= ~Math.pow(2, data[1]);
	}

	get(index)
	{
		let data = this._calculateArrayIndexAndExponent(index);
		return (this._array[data[0]] & Math.pow(2, data[1])) > 0;
	}

	has(indices = [])
	{
		if (indices.length == 0) return false;
		let values = toString();

		let returnData = false;
		
	}

	size()
	{
		return this._array.length;
	}

	visualizeBits(integer, withPaddingLength)
	{
		let string = integer.toString(2);
		return string.padStart(withPaddingLength, "0");
	}

	toString(delimiter)
	{
		let returnData = [];

		for(let i = this._array.length-1; i > -1; i--)
			returnData.push(this.visualizeBits(this._array[i], 8));

		return returnData.join(delimiter || "");
	}
}