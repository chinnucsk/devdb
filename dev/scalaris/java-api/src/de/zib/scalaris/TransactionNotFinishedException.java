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
package de.zib.scalaris;

/**
 * Exception that is thrown when a new transaction is started although the old
 * one has not been committed or aborted.
 * 
 * @author Nico Kruber, kruber@zib.de
 * @version 2.0
 * @since 2.0
 */
public class TransactionNotFinishedException extends Exception {
	/**
	 * class version for serialisation
	 */
	private static final long serialVersionUID = 1L;

	/**
	 * Creates the exception with no message.
	 */
	public TransactionNotFinishedException() {
		super("Cannot start a new transaction until the old one is not committed or aborted.");
	}

	/**
	 * Creates the exception with the given message.
	 * 
	 * @param msg
	 *            message of the exception
	 */
	public TransactionNotFinishedException(String msg) {
		super(msg);
	}
	
	/**
	 * Creates an exception taking the message of the given throwable.
	 * 
	 * @param e the exception to "re-throw"
	 */
	public TransactionNotFinishedException(Throwable e) {
		super(e.getMessage());
		setStackTrace(e.getStackTrace());
	}
}
