WITH item_sales AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        SUM(cs.cs_net_profit) AS catalog_profit,
        SUM(ss.ss_net_profit) AS store_profit,
        SUM(ws.ws_net_profit) AS web_profit,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_tickets,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders
    FROM
        item i
        LEFT JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
        LEFT JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
        LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
        LEFT JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        LEFT JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
        LEFT JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        LEFT JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
        LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
                                      AND cr.cr_item_sk = i.i_item_sk
    WHERE
        cs.cs_quantity > 5
        AND cs.cs_sales_price > 100
        AND cp.cp_catalog_number IN (4, 7)
        AND i.i_current_price BETWEEN 20 AND 200
        AND hd.hd_buy_potential = 'HIGH'
        AND ib.ib_upper_bound > 50000
        AND td.t_hour BETWEEN 9 AND 17
        AND ss.ss_coupon_amt > 0
        AND ws.ws_net_profit < 0
    GROUP BY
        i.i_item_sk,
        i.i_product_name
)
SELECT
    i_item_sk,
    i_product_name,
    catalog_profit,
    store_profit,
    web_profit,
    (catalog_profit + store_profit + web_profit) AS total_profit,
    CASE WHEN (catalog_profit + store_profit + web_profit) > 10000 THEN 'HIGH' ELSE 'LOW' END AS profit_category,
    ROW_NUMBER() OVER (ORDER BY (catalog_profit + store_profit + web_profit) DESC) AS profit_rank,
    (SELECT AVG(catalog_profit) FROM item_sales) AS avg_catalog_profit
FROM
    item_sales
ORDER BY
    profit_rank
LIMIT 100
