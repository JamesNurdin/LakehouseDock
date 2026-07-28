WITH sales_agg AS (
    SELECT
        d.d_year,
        s.s_store_id,
        SUM(cs.cs_net_profit) AS catalog_profit,
        SUM(web.ws_net_profit) AS web_profit,
        SUM(cs.cs_net_profit) + SUM(web.ws_net_profit) AS total_profit
    FROM tpcds.date_dim d
    JOIN tpcds.call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
    JOIN tpcds.catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
    JOIN tpcds.inventory i ON i.inv_date_sk = d.d_date_sk
    JOIN tpcds.store s ON s.s_closed_date_sk = d.d_date_sk
    JOIN tpcds.web_site ws_site ON ws_site.web_open_date_sk = d.d_date_sk
    JOIN tpcds.catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN tpcds.web_sales web ON web.ws_sold_date_sk = d.d_date_sk
    JOIN tpcds.store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN tpcds.reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN tpcds.customer_address ca ON ca.ca_address_sk = cs.cs_bill_addr_sk
    JOIN tpcds.catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
        AND cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    WHERE d.d_year = 2001
        AND cs.cs_quantity > 5
        AND cr.cr_return_amount > 100.00
        AND ca.ca_state = 'TX'
        AND web.ws_quantity < 10
    GROUP BY d.d_year, s.s_store_id
)
SELECT
    sa.d_year,
    sa.s_store_id,
    sa.total_profit,
    ROW_NUMBER() OVER (PARTITION BY sa.d_year ORDER BY sa.total_profit DESC) AS profit_rank,
    (
        SELECT MAX(cr2.cr_return_amount)
        FROM tpcds.catalog_returns cr2
        JOIN tpcds.date_dim d2 ON cr2.cr_returned_date_sk = d2.d_date_sk
        WHERE d2.d_year = sa.d_year
    ) AS max_return_amount_year
FROM sales_agg sa
WHERE sa.total_profit > (
    SELECT AVG(total_profit) * 1.2
    FROM sales_agg
    WHERE d_year = sa.d_year
)
ORDER BY sa.d_year, profit_rank
LIMIT 10
