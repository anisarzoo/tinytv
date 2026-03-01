/**
 * Tivy Custom Dropdown Helper
 * Replaces native selects with theme-based custom dropdowns
 */

export class TivyDropdown {
    constructor(selectElement, options = {}) {
        this.select = selectElement;
        this.options = options;
        this.container = null;
        this.trigger = null;
        this.optionsList = null;
        this.isOpen = false;

        this.init();
    }

    init() {
        // Hide original select
        this.select.style.display = 'none';

        // Create container
        this.container = document.createElement('div');
        this.container.className = 'tivy-select';
        if (this.select.id) this.container.id = `tivy-custom-${this.select.id}`;

        // Create trigger
        this.trigger = document.createElement('div');
        this.trigger.className = 'tivy-select-trigger';
        this.trigger.innerHTML = `
            <span class="tivy-select-label">${this.getSelectedLabel()}</span>
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <polyline points="6 9 12 15 18 9"></polyline>
            </svg>
        `;

        // Create options list
        this.optionsList = document.createElement('div');
        this.optionsList.className = 'tivy-select-options';
        this.renderOptions();

        // Assemble
        this.container.appendChild(this.trigger);
        this.container.appendChild(this.optionsList);
        this.select.parentNode.insertBefore(this.container, this.select.nextSibling);

        // Events
        this.trigger.addEventListener('click', () => this.toggle());
        document.addEventListener('click', (e) => {
            if (!this.container.contains(e.target)) this.close();
        });
    }

    getSelectedLabel() {
        const selectedOption = this.select.options[this.select.selectedIndex];
        return selectedOption ? selectedOption.text : 'Select...';
    }

    renderOptions() {
        this.optionsList.innerHTML = '';
        Array.from(this.select.options).forEach((opt, index) => {
            const optionDiv = document.createElement('div');
            optionDiv.className = `tivy-select-option ${index === this.select.selectedIndex ? 'selected' : ''}`;
            optionDiv.textContent = opt.text;
            optionDiv.dataset.value = opt.value;
            optionDiv.dataset.index = index;

            optionDiv.addEventListener('click', () => this.selectOption(index));
            this.optionsList.appendChild(optionDiv);
        });
    }

    toggle() {
        this.isOpen ? this.close() : this.open();
    }

    open() {
        // Close other open dropdowns first
        document.querySelectorAll('.tivy-select.open').forEach(el => {
            if (el !== this.container) el.classList.remove('open');
        });

        this.isOpen = true;
        this.container.classList.add('open');
    }

    close() {
        this.isOpen = false;
        this.container.classList.remove('open');
    }

    selectOption(index) {
        this.select.selectedIndex = index;

        // Update UI
        this.trigger.querySelector('.tivy-select-label').textContent = this.select.options[index].text;

        // Update selected class
        this.optionsList.querySelectorAll('.tivy-select-option').forEach((el, i) => {
            el.classList.toggle('selected', i === index);
        });

        this.close();

        // Trigger native change event
        this.select.dispatchEvent(new Event('change', { bubbles: true }));
    }

    // Call this if the underlying select options change dynamically
    update() {
        this.renderOptions();
        this.trigger.querySelector('.tivy-select-label').textContent = this.getSelectedLabel();
    }
}

/**
 * Initializes all selects with a certain selector
 * @param {string} selector 
 */
export function initAllDropdowns(selector = '.modern-select, .sidebar-filter-select, .desktop-filter-select') {
    const dropdowns = [];
    document.querySelectorAll(selector).forEach(select => {
        // Avoid double initialization
        if (select.dataset.tivyDropdownInited) return;

        const dropdown = new TivyDropdown(select);
        select.dataset.tivyDropdownInited = 'true';
        dropdowns.push(dropdown);

        // Expose dropdown instance on the element
        select._tivyDropdown = dropdown;
    });
    return dropdowns;
}
