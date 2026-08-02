WITH exclusive_cat_items AS (
    SELECT cr_item_sk AS item_sk
    FROM catalog_returns
    EXCEPT
    SELECT wr_item_sk
    FROM web_returns
),
base_agg AS (
    SELECT
        s.s_store_name AS store_name,
        ss.ss_sold_date_sk AS sold_date_sk,
        SUM(ss.ss_net_profit) AS total_sales_profit,
        SUM(cr.cr_net_loss) AS total_return_loss,
        (SUM(ss.ss_net_profit) - SUM(cr.cr_net_loss)) AS net_total
    FROM
        store_sales ss
        JOIN item i_sales ON ss.ss_item_sk = i_sales.i_item_sk
        JOIN exclusive_cat_items eci ON i_sales.i_item_sk = eci.item_sk
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
        JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        JOIN inventory inv ON i_sales.i_item_sk = inv.inv_item_sk
        JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
        JOIN catalog_returns cr ON i_sales.i_item_sk = cr.cr_item_sk AND w.w_warehouse_sk = cr.cr_warehouse_sk
        JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
        JOIN item i_returns ON cr.cr_item_sk = i_returns.i_item_sk
        JOIN web_returns wr ON i_returns.i_item_sk = wr.wr_item_sk
        JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE
        ca.ca_state = 'CA'
    GROUP BY
        s.s_store_name,
        ss.ss_sold_date_sk
)
SELECT
    store_name,
    sold_date_sk,
    total_sales_profit,
    total_return_loss,
    net_total,
    SUM(net_total) OVER (PARTITION BY store_name ORDER BY sold_date_sk) AS running_net_total,
    LAG(total_sales_profit) OVER (PARTITION BY store_name ORDER BY sold_date_sk) AS prev_sales_profit
FROM base_agg
ORDER BY store_name, sold_date_sk
LIMIT 100
