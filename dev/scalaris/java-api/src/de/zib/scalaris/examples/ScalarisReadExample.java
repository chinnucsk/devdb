/**
 *  Copyright 2007-2008 Konrad-Zuse-Zentrum für Informationstechnik Berlin
 *
 *   Licensed under the Apache License, Version 2.0 (the "License");
 *   you may not use this file except in compliance with the License.
 *   You may obtain a copy of the License at
 *
 *       http://www.apache.org/licenses/LICENSE-2.0
 *
 *   Unless required by applicable law or agreed to in writing, software
 *   distributed under the License is distributed on an "AS IS" BASIS,
 *   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *   See the License for the specific language governing permissions and
 *   limitations under the License.
 */
package de.zib.scalaris.examples;

import com.ericsson.otp.erlang.OtpErlangString;

import de.zib.scalaris.ConnectionException;
import de.zib.scalaris.NotFoundException;
import de.zib.scalaris.Scalaris;
import de.zib.scalaris.TimeoutException;
import de.zib.scalaris.UnknownException;

/**
 * Provides an example for using the <tt>read</tt> methods of the
 * {@link Scalaris} class.
 * 
 * @author Nico Kruber, kruber@zib.de
 * @version 2.0
 * @since 2.0
 */
public class ScalarisReadExample {
	/**
	 * Reads a key given on the command line with the <tt>read</tt> methods of
	 * {@link Scalaris}.<br />
	 * If no key is given, the default key <tt>"key"</tt> is used.
	 * 
	 * @param args
	 *            command line arguments (first argument can be an optional key
	 *            to look up)
	 */
	public static void main(String[] args) {
		String key;
		String value;

		if (args.length != 1) {
			key = "key";
		} else {
			key = args[0];
		}

		OtpErlangString otpKey = new OtpErlangString(key);
		OtpErlangString otpValue;

		System.out.println("Reading values with the class `Scalaris`:");

		try {
			System.out.println("  creating object...");
			Scalaris sc = new Scalaris();
			System.out
					.println("    `OtpErlangObject readObject(OtpErlangString)`...");
			otpValue = (OtpErlangString) sc.readObject(otpKey);
			System.out.println("      read(" + otpKey.stringValue() + ") == "
					+ otpValue.stringValue());
		} catch (ConnectionException e) {
			System.out.println("      read(" + otpKey.stringValue()
					+ ") failed: " + e.getMessage());
		} catch (TimeoutException e) {
			System.out.println("      read(" + otpKey.stringValue()
					+ ") failed with timeout: " + e.getMessage());
		} catch (UnknownException e) {
			System.out.println("      read(" + otpKey.stringValue()
					+ ") failed with unknown: " + e.getMessage());
		} catch (NotFoundException e) {
			System.out.println("      read(" + otpKey.stringValue()
					+ ") failed with not found: " + e.getMessage());
		} catch (ClassCastException e) {
			System.out.println("      read(" + otpKey.stringValue()
					+ ") failed with unknown return type: " + e.getMessage());
		}

		try {
			System.out.println("  creating object...");
			Scalaris sc = new Scalaris();
			System.out.println("    `String read(String)`...");
			value = sc.read(key);
			System.out.println("      read(" + key + ") == " + value);
		} catch (ConnectionException e) {
			System.out.println("      read(" + key + ") failed: "
					+ e.getMessage());
		} catch (TimeoutException e) {
			System.out.println("      read(" + key + ") failed with timeout: "
					+ e.getMessage());
		} catch (UnknownException e) {
			System.out.println("      read(" + key + ") failed with unknown: "
					+ e.getMessage());
		} catch (NotFoundException e) {
			System.out.println("      read(" + key
					+ ") failed with not found: " + e.getMessage());
		}
	}
}
