
interface IGlobalState {
    TableRows: Array<TableRow>
}

interface TableRow {
    Col1: string
    Col2: string
}

const GlobalState: IGlobalState = {
    TableRows: []
}

window.onload = function() {
    update();
    document.querySelector('#AddRow')!.addEventListener('click', onAddRow);
    console.log('Initialized');
}

function onAddRow(): void {
    let col1 = document.querySelector<HTMLInputElement>('#NewRowCol1Value')!.value;
    let col2 = document.querySelector<HTMLInputElement>('#NewRowCol2Value')!.value;

    if (col1.trim().length == 0 && col2.trim().length == 0) {
        return;
    }

    GlobalState.TableRows.push({
        Col1: col1,
        Col2: col2
    });

    update();
}

function onDeleteRow(index: number): void {
    GlobalState.TableRows.splice(index, 1);
    update();
}

function createHTML(htmlString: string): Element {
    const template = document.createElement('template');
    template.innerHTML = htmlString.trim();
    return template.content.firstElementChild!;
}

function updateTable(): void {
    let tableBody = document.querySelector<HTMLTableElement>('#TheTable')!;
    tableBody.innerHTML = '';

    GlobalState.TableRows.forEach((row,index) => {
        let deleteButton = createHTML(`<button>DELETE</button>`);
        deleteButton.addEventListener('click', onDeleteRow.bind(deleteButton, index));

        let newRow = createHTML(`
            <tr>
                <td>${row.Col1}</td>
                <td>${row.Col2}</td>
            </tr>
        `);
        newRow.appendChild(document.createElement('td')).appendChild(deleteButton);
        tableBody.append(newRow);
    });
}

function updateTableRowCounter(): void {
    let element = document.querySelector<HTMLSpanElement>('#RowCounter')!;
    element.innerText = `${GlobalState.TableRows.length} rows`;
}

function updateAddRow(): void {
    document.querySelector<HTMLInputElement>('#NewRowCol1Value')!.value = '';
    document.querySelector<HTMLInputElement>('#NewRowCol2Value')!.value = '';
}

function update(): void {
    updateTable();
    updateTableRowCounter();
    updateAddRow();
}