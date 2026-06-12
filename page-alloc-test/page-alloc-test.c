// SPDX-License-Identifier: GPL-2.0+
/*
 * test_free_pages.c: Check that free_pages() doesn't leak memory
 * Copyright (c) 2020 Oracle
 * Author: Matthew Wilcox <willy@infradead.org>
 * (Brendan Jackman: Copied from lib/free_pages_test.c in Linux kernel, added
 * timing printks)
 */

#define pr_fmt(fmt)	KBUILD_MODNAME ": " fmt

#include <linux/gfp.h>
#include <linux/mm.h>
#include <linux/module.h>
#include <linux/ktime.h>

static void test_free_pages(gfp_t gfp)
{
	unsigned int i;
	ktime_t start, end;
	s64 delta;
	u64 total_ns;
	u64 avg_ns_x100;
	u64 avg_integer;
	u64 avg_fraction;

	pr_info("Starting 1,000,000 allocations...\n");
	start = ktime_get();
	for (i = 0; i < 1000 * 1000; i++) {
		unsigned long addr = __get_free_pages(gfp, 3);
		struct page *page = virt_to_page((void *)addr);

		/* Simulate page cache getting a speculative reference */
		get_page(page);
		free_pages(addr, 3);
		put_page(page);
	}
	end = ktime_get();
	delta = ktime_to_us(ktime_sub(end, start));
	total_ns = ktime_to_ns(ktime_sub(end, start));
	avg_ns_x100 = (total_ns * 100) / (1000 * 1000);
	avg_integer = avg_ns_x100 / 100;
	avg_fraction = avg_ns_x100 % 100;

	pr_info("Completed. Time: %lld us (Avg: %llu.%02llu ns per alloc+free loop)\n",
		delta, avg_integer, avg_fraction);
}

static int m_in(void)
{
	pr_info("Testing with GFP_KERNEL\n");
	test_free_pages(GFP_KERNEL);
	pr_info("Testing with GFP_KERNEL | __GFP_COMP\n");
	test_free_pages(GFP_KERNEL | __GFP_COMP);
	pr_info("Test completed\n");

	return 0;
}

static void m_ex(void)
{
}

module_init(m_in);
module_exit(m_ex);
MODULE_AUTHOR("Matthew Wilcox <willy@infradead.org>");
MODULE_DESCRIPTION("Check that free_pages() doesn't leak memory");
MODULE_LICENSE("GPL");
