/*
 * Copyright (c) 2018 WSO2 Inc. (http:www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http:www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package commands

import (
	"bufio"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"strings"

	"github.com/olekukonko/tablewriter"

	"github.com/cellery-io/sdk/components/cli/pkg/constants"
	"github.com/cellery-io/sdk/components/cli/pkg/util"
)

func RunComponents(cellName string) {
	cmd := exec.Command("kubectl", "get", "services", "-l", constants.GROUP_NAME+"/cell="+cellName, "-o", "json")
	stdoutReader, _ := cmd.StdoutPipe()
	stdoutScanner := bufio.NewScanner(stdoutReader)
	output := constants.EMPTY_STRING
	go func() {
		for stdoutScanner.Scan() {
			output = output + stdoutScanner.Text()
		}
	}()
	stderrReader, _ := cmd.StderrPipe()
	stderrScanner := bufio.NewScanner(stderrReader)
	go func() {
		for stderrScanner.Scan() {
			fmt.Println(stderrScanner.Text())
		}
	}()
	err := cmd.Start()
	if err != nil {
		util.ExitWithErrorMessage("Error occurred while fetching components", err)
	}
	err = cmd.Wait()
	if err != nil {
		util.ExitWithErrorMessage("Error occurred while fetching components", err)
	}

	jsonOutput := &util.Service{}

	errJson := json.Unmarshal([]byte(output), jsonOutput)
	if errJson != nil {
		fmt.Println(errJson)
	}

	if len(jsonOutput.Items) == 0 {
		fmt.Printf("Cannot find cell: %v \n", cellName)
	} else {
		displayComponentsTable(jsonOutput.Items, cellName)
	}
}

func displayComponentsTable(componentArray []util.ServiceItem, cellName string) {
	var tableData [][]string

	for i := 0; i < len(componentArray); i++ {
		var name string
		name = strings.Replace(componentArray[i].Metadata.Name, cellName+"--", "", -1)
		name = strings.Replace(name, "-service", "", -1)

		//ports := strconv.Itoa(componentArray[i].Spec.Ports[0].Port)
		//for j := 1; j < len(componentArray[i].Spec.Ports); j++ {
		//	ports = ports + "/" + strconv.Itoa(componentArray[i].Spec.Ports[j].Port)
		//}
		component := []string{name}
		tableData = append(tableData, component)
	}

	table := tablewriter.NewWriter(os.Stdout)
	table.SetHeader([]string{"COMPONENT NAME"})
	table.SetBorders(tablewriter.Border{Left: false, Top: false, Right: false, Bottom: false})
	table.SetAlignment(3)
	table.SetRowSeparator("-")
	table.SetCenterSeparator(" ")
	table.SetColumnSeparator(" ")
	table.SetHeaderColor(tablewriter.Colors{tablewriter.Bold})
	table.SetColumnColor(tablewriter.Colors{tablewriter.FgHiBlueColor})

	table.AppendBulk(tableData)
	table.Render()
}
