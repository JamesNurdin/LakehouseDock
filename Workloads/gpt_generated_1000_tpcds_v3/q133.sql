WITH raw_sales AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        wp.wp_web_page_sk,
        wp.wp_url,
        d_sold.d_date,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        SUM(ws.ws_net_profit) AS web_net_profit,
        SUM(COALESCE(wr.wr_net_loss, 0)) AS returns_net_loss,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM
        catalog_sales cs
        JOIN date_dim d_sold
            ON cs.cs_sold_date_sk = d_sold.d_date_sk
        JOIN call_center cc
            ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN catalog_page cp
            ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN customer c_bill
            ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
        JOIN customer_demographics cd_bill
            ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
        JOIN web_sales ws
            ON ws.ws_sold_date_sk = d_sold.d_date_sk
            AND ws.ws_bill_customer_sk = c_bill.c_customer_sk
        JOIN web_page wp
            ON ws.ws_web_page_sk = wp.wp_web_page_sk
        LEFT JOIN web_returns wr
            ON wr.wr_order_number = ws.ws_order_number
            AND wr.wr_item_sk = ws.ws_item_sk
            AND wr.wr_returned_date_sk = d_sold.d_date_sk
        JOIN inventory inv
            ON inv.inv_date_sk = d_sold.d_date_sk
        JOIN store s
            ON s.s_closed_date_sk = d_sold.d_date_sk
    WHERE
        d_sold.d_year = 2002
        AND cd_bill.cd_gender = 'M'
        AND cp.cp_catalog_number BETWEEN 5 AND 15
        AND inv.inv_quantity_on_hand > 100
        AND cc.cc_name LIKE '%Sycamore%'
    GROUP BY
        cc.cc_call_center_sk,
        cc.cc_name,
        wp.wp_web_page_sk,
        wp.wp_url,
        d_sold.d_date
)
SELECT
    rs.cc_name,
    SUM(rs.catalog_net_profit + rs.web_net_profit - rs.returns_net_loss) AS call_center_total_profit,
    AVG(rs.catalog_net_profit + rs.web_net_profit - rs.returns_net_loss) AS avg_profit_per_day,
    COUNT(*) AS num_days
FROM
    raw_sales rs
GROUP BY
    rs.cc_name
HAVING
    SUM(rs.catalog_net_profit + rs.web_net_profit - rs.returns_net_loss) > (
        SELECT AVG(total_profit)
        FROM (
            SELECT (catalog_net_profit + web_net_profit - returns_net_loss) AS total_profit
            FROM raw_sales
        ) t
    )
ORDER BY
    call_center_total_profit DESC
LIMIT 100
