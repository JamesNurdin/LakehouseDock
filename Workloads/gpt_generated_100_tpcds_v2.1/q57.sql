WITH store_item_customer_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        i.i_item_id,
        i.i_product_name,
        c.c_customer_id,
        cd.cd_gender,
        ca.ca_city,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(COALESCE(sr.sr_return_amt, 0)) AS total_returns,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(*) AS sales_transactions
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    WHERE i.i_rec_start_date >= DATE '2001-01-01'
      AND i.i_rec_end_date <= DATE '2002-12-31'
      AND cd.cd_gender = 'M'
      AND ca.ca_city IN ('Springfield', 'Lakeview')
      AND ss.ss_list_price > 50
      AND s.s_gmt_offset >= -6.00
    GROUP BY s.s_store_id, s.s_store_name, i.i_item_id, i.i_product_name, c.c_customer_id, cd.cd_gender, ca.ca_city
)
SELECT
    agg.s_store_id,
    agg.s_store_name,
    agg.i_item_id,
    agg.i_product_name,
    agg.c_customer_id,
    agg.ca_city,
    agg.total_sales,
    agg.total_returns,
    agg.total_net_profit,
    agg.sales_transactions,
    ROW_NUMBER() OVER (PARTITION BY agg.ca_city ORDER BY agg.total_sales DESC) AS city_sales_rank,
    CASE WHEN agg.total_sales > 0 THEN agg.total_net_profit / agg.total_sales ELSE NULL END AS net_profit_margin
FROM store_item_customer_agg agg
WHERE agg.total_net_profit > (
    SELECT AVG(sub.total_net_profit)
    FROM store_item_customer_agg sub
    WHERE sub.s_store_id = agg.s_store_id
) AND agg.sales_transactions >= 5
ORDER BY agg.total_net_profit DESC, agg.total_sales DESC
LIMIT 100
