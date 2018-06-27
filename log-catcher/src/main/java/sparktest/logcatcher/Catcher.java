package sparktest.logcatcher;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.io.Writer;
import java.text.SimpleDateFormat;
import java.util.Arrays;
import java.util.Calendar;
import java.util.TimeZone;
import java.util.logging.Level;
import java.util.logging.Logger;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.bind.annotation.RestController;

@SpringBootApplication
@RestController
@Deprecated
public class Catcher {

	private static final Logger LOGGER = Logger.getLogger(Catcher.class.getName());
	private static final String LOG_DIRECTORY = "/var/log-catcher/logs";

	public static void main(final String[] args) {
		SpringApplication.run(Catcher.class, args);
	}

	private void makeDirectories() {
		File logs = new File(LOG_DIRECTORY);
		if (logs.exists()) {
			if (logs.isDirectory()) {
				LOGGER.info("Log directory already exists.");
				return;
			}
			throw new RuntimeException(
					"Path '" + LOG_DIRECTORY + "' is not a directory, but still exists. Change any of these facts!");
		}
		boolean result = logs.mkdir();
		if (result) {
			LOGGER.info("Created directories to '" + LOG_DIRECTORY + "'.");
		} else {
			throw new RuntimeException("Failed to create '" + LOG_DIRECTORY + "'.");
		}

	}

	public Catcher() {
		this.makeDirectories();
		sdf.setTimeZone(TimeZone.getTimeZone("GMT+2:00"));
	}

	private static Calendar cal = Calendar.getInstance();
	private static SimpleDateFormat sdf = new SimpleDateFormat("HH:mm:ss");

	// @formatter:off
	@RequestMapping(path = "/log", method = {
			RequestMethod.POST })
	public @ResponseBody() ResponseEntity<String> postLogs(
			@RequestParam("message") final String[] messages,
			@RequestParam("identifier") final String id
		) {
		for(String message : messages) {
		System.out.println("["+id+"] "+sdf.format(cal.getTime())+": "+message);
		}
		// @formatter:on
		synchronized (id) {
			try (Writer output = new BufferedWriter(new FileWriter(LOG_DIRECTORY + "/log_" + id + ".log", true))) {
				for (String message : messages) {
					output.write(message + "\n");
				}
			} catch (IOException e) {
				LOGGER.log(Level.SEVERE, "Failed to write to file.", e);
				LOGGER.log(Level.INFO, "Messages: " + Arrays.toString(messages));
				return new ResponseEntity<>(e.getStackTrace().toString(), HttpStatus.INTERNAL_SERVER_ERROR);
			}
		}
		return new ResponseEntity<>(HttpStatus.OK);
	}

	// @formatter:off
	@RequestMapping(path = "/logs", method = {
			RequestMethod.POST })
	public @ResponseBody() ResponseEntity<String> postLog(
			@RequestParam("message") final String message,
			@RequestParam("identifier") final String id
		) {
		// @formatter:on
		System.out.println("[" + id + "] " + sdf.format(cal.getTime()) + ": " + message);

		try (Writer output = new BufferedWriter(
				new FileWriter(LOG_DIRECTORY + File.pathSeparator + "log_" + id + ".log", true))) {
			output.write(message + "\n");
		} catch (IOException e) {
			LOGGER.log(Level.SEVERE, "Failed to write to file.", e);
			LOGGER.log(Level.INFO, "Message: " + message);
			return new ResponseEntity<>(e.getStackTrace().toString(), HttpStatus.INTERNAL_SERVER_ERROR);
		}

		return new ResponseEntity<>(HttpStatus.OK);
	}

	@RequestMapping(path = "/ping", method = {RequestMethod.GET})
	public ResponseEntity<Void> ping() {
		System.out.println("I was pinged.");
		return new ResponseEntity<>(HttpStatus.OK);
	}
}
