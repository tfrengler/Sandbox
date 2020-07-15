"use strict";

class System {

	static update(entities, target) {
		let deltaTime = performance.now() - lastUpdate;
		document.querySelector("#updateTime").textContent = deltaTime.toFixed(2) + " ms";
		document.querySelector("#fps").textContent = Math.floor(1000 / deltaTime) + " fps";
		deltaTime = deltaTime / 1000;

		entities.forEach(entity => {

			let speed = 3 * deltaTime;
			let brakeSpeed = speed * 0.20;
			var acceleration = new Vector();

			if (keysPressed.left)
				entity.angle = entity.angle - 0.02;
			else if (keysPressed.right)
				entity.angle = entity.angle + 0.02;

			// -cos because our coordinate system is flipped (0,0 is the top-left corner of the screen)
			if (keysPressed.up) {
				acceleration.x = Math.sin(entity.angle) * speed;
				acceleration.y = -Math.cos(entity.angle) * speed;
			}
			else if (keysPressed.down) {
				acceleration.x = Math.sin(entity.angle) * -brakeSpeed;
				acceleration.y = -Math.cos(entity.angle) * -brakeSpeed;
			}

			// if (!keysPressed.up && !keysPressed.down)
			// 	acceleration = entity.velocity.copy().mult(-1).mult(0.02);

			this.checkCollision(entity);
			if ((entity.collision >> 4) === 1) this.resolveCollision(entity);

			entity.velocity.add(acceleration);
			entity.velocity.limit(entity.maxSpeed);

			// reset insignificant amounts to 0
			if (entity.velocity.x < System.threshold && entity.velocity.x > -System.threshold)
				entity.velocity.x = 0;
			if (entity.velocity.y < System.threshold && entity.velocity.y > -System.threshold)
				entity.velocity.y = 0;

			entity.location.add(entity.velocity);
			// entity.angleVelocity += entity.angleAcceleration;
			// entity.angle += entity.angleVelocity;
			
			//entity.acceleration.mult(0); // Clear acceleration each time, otherwise it accumulates and goes out of whack

			if (performance.now() - lastUIUpdate > 500) {

				document.querySelector("#Velocity").textContent = `{X: ${entity.velocity.x.toFixed(2)}, Y: ${entity.velocity.y.toFixed(2)}}`;
				document.querySelector("#VelocityMag").textContent = entity.velocity.mag().toFixed(2);
				document.querySelector("#KeysPressed").textContent = `LEFT: ${keysPressed.left}, RIGHT: ${keysPressed.right}, UP: ${keysPressed.up}, DOWN: ${keysPressed.down}`;

				lastUIUpdate = performance.now();
			}
		});

		this.render(entities);
		lastUpdate = performance.now();
	}

	static resolveCollision(entity) {
		// LEFT		| 00011000 | 24
		if ((entity.collision & 24) === 24) {
			entity.collision = 0;
			entity.velocity.x *= -1;
			entity.velocity.x /= entity.mass;
		}
		// RIGHT	| 00010100 | 20
		else if ((entity.collision & 20) === 20) {
			entity.collision = 0;
			entity.velocity.x *= -1;
			entity.velocity.x /= entity.mass;
		}

		// BOTTOM	| 00010001 | 17
		if ((entity.collision & 17) === 17) {
			entity.collision = 0;
			entity.velocity.y *= -1;
			entity.velocity.y /= entity.mass;
		}
		// TOP		| 00010010 | 18
		else if ((entity.collision & 18) === 18) {
			entity.collision = 0;
			entity.velocity.y *= -1;
			entity.velocity.y /= entity.mass;
		}
	};

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

			drawContext.save();
			drawContext.translate(Math.floor(entity.location.x), Math.floor(entity.location.y));
			drawContext.rotate(entity.angle);

			

			if (["RECTANGLE","SQUARE"].includes(entity.shape.type)) {

				drawContext.strokeStyle  = entity.shape.borderColor;
				drawContext.beginPath();

				drawContext.rect(
					Math.floor(-entity.shape.width / 2), Math.floor(-entity.shape.height / 2),
					entity.shape.width,
					entity.shape.height
				);
				drawContext.stroke();

				drawContext.beginPath();
				drawContext.strokeStyle  = "red";

				drawContext.moveTo(0,0);
				drawContext.lineTo(0, -(entity.shape.height / 2));
				drawContext.stroke();

				drawContext.beginPath();
				drawContext.fillStyle = "red";
				drawContext.fillRect(0, 0, 1, 1);
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
			drawContext.restore();
		})
	}
}
System.threshold = 0.01;