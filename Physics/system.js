"use strict";

class System {

	static getAcceleration(entity, target) {
		let direction = Vector.sub(target, entity.location); // Calculate a vector that points from the object to the target location
		direction.normalize(); // Normalize that vector (reducing its length to 1 "unit")
		direction.mult(0.5 * entity.mass); // Scale that vector to an appropriate value (by multiplying it by some value)

		return direction;
	}

	static update(entities, target) {
		entities.forEach(entity => {

			// If we have a target, calculate acceleration, otherwise use the existing acceleration
			if (target)
				entity.acceleration = this.getAcceleration(entity, target);

			this.applyForce(entity, this.getDrag(entity, System.airFriction)); // Normal air density friction
			this.applyForce(entity, new Vector(System.wind, 0)); // Wind, only coming from left or right
			this.applyForce(entity, new Vector(0, System.gravity * entity.mass)); // Gravity

			entity.velocity.add(entity.acceleration);
			entity.velocity.limit(entity.maxSpeed);
			entity.location.add(entity.velocity);

			// entity.angleVelocity += entity.angleAcceleration;
			// entity.angle += entity.angleVelocity;
			
			this.checkCollision(entity);
			if ((entity.collision >> 4) === 1) this.resolveCollision(entity);

			entity.acceleration.mult(0); // Clear acceleration each time, otherwise it accumulates and goes out of whack
		});

		this.render(entities);
	}

	static getFriction(entity, coefficient) {
		let friction = entity.velocity.copy();

		friction.mult(-1);
		friction.normalize();
		friction.mult(coefficient);

		return friction;
	}

	static getDrag(entity, coefficient) {
		let speed = entity.velocity.mag();
		let dragMagnitude = coefficient * speed * speed;

		let drag = entity.velocity.copy();
		drag.mult(-1);
		drag.normalize();
		drag.mult(dragMagnitude);

		return drag;
	}

	static resolveCollision(entity) {
		// LEFT		| 00011000 | 24
		if ((entity.collision & 24) === 24) {
			entity.collision = 0;
			// entity.location.x = 0;
			entity.velocity.x *= -1;
			entity.velocity.x /= entity.mass;
		}
		// RIGHT	| 00010100 | 20
		else if ((entity.collision & 20) === 20) {
			entity.collision = 0;
			// entity.location.x = canvas.width;
			entity.velocity.x *= -1;
			entity.velocity.x /= entity.mass;
		}

		// BOTTOM	| 00010001 | 17
		if ((entity.collision & 17) === 17) {
			entity.collision = 0;
			// entity.location.y = canvas.height;
			entity.velocity.y *= -1;
			entity.velocity.y /= entity.mass;
		}
		// TOP		| 00010010 | 18
		else if ((entity.collision & 18) === 18) {
			entity.collision = 0;
			// entity.location.y = 0;
			entity.velocity.y *= -1;
			entity.velocity.y /= entity.mass;
		}
	};

	// TODO(thomas): Maybe make this return data about which axis collided? Set the location but return X or Y? Maybe side?
	static checkCollision(entity) {

		let leftCalculation, rightCalculation, bottomCalculation, topCalculation;

		if (["RECTANGLE","SQUARE"].includes(entity.shape.type)) {
			leftCalculation = entity.shape.width / 2;
			rightCalculation = entity.shape.width / 2;
			bottomCalculation = entity.shape.height / 2;
			topCalculation = entity.shape.height / 2;
		}
		else if (entity.shape.type === "CIRCLE") {
			leftCalculation = entity.shape.radius;
			rightCalculation = entity.shape.radius;
			bottomCalculation = entity.shape.radius;
			topCalculation = entity.shape.radius;
		}
		
		// 00000000
		// 000XLRTB
		/*
			5: Collision
			4: Left
			3: Right
			2: Top
			1: Bottom
		*/

		// LEFT 00011000
		if (entity.location.x - leftCalculation < 0) {
			entity.location.x = leftCalculation + 0;
			entity.collision |= 24;
		} // RIGHT 00010100
		else if (entity.location.x + rightCalculation > canvas.width) {
			entity.location.x = canvas.width - rightCalculation;
			entity.collision |= 20;
		}

		// BOTTOM 00010001
		if (entity.location.y + bottomCalculation > canvas.height) {
			entity.location.y = canvas.height - bottomCalculation;
			entity.collision |= 17;
		} // TOP 00010010
		else if (entity.location.y - topCalculation < 0) {
			entity.location.y = topCalculation;
			entity.collision |= 18;
		}
	}

	static radians(degrees) {
		return degrees * (Math.PI / 180);
	}

	static degrees(radians) {
		return radians * (180 / Math.PI);
	}

	static render(entities) {
		drawContext.clearRect(0, 0, canvas.width, canvas.height);

		entities.forEach(entity => {

			drawContext.beginPath();
			drawContext.strokeStyle  = entity.shape.borderColor;

			if (["RECTANGLE","SQUARE"].includes(entity.shape.type)) {
				drawContext.rect(
					Math.floor(entity.location.x - (entity.shape.width / 2)),
					Math.floor(entity.location.y - (entity.shape.height / 2)),
					entity.shape.width,
					entity.shape.height
				);
			};

			if (entity.shape.type === "CIRCLE") {

				drawContext.arc(
					Math.floor(entity.location.x),
					Math.floor(entity.location.y),
					entity.shape.radius,
					0,
					2 * Math.PI
				);
			}
			
			drawContext.stroke();
		})
	}

	static applyForce(entity, force) {
		let forceAfterMass = Vector.div(force, entity.mass);
		entity.acceleration.add(forceAfterMass);
	}
}

System.gravity = 0.2;
System.airFriction = 0.002;
System.wind = 0.008;

/*

friction
wind
gravity
drag

velocity
*/