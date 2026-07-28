WITH inv_agg AS (
    SELECT
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_quantity_on_hand
    FROM inventory
    GROUP BY inv_warehouse_sk
)
SELECT
    w.w_warehouse_id,
    w.w_warehouse_name,
    w.w_county,
    SUM(cs.cs_ext_sales_price)               AS total_sales,
    SUM(cs.cs_net_profit)                    AS total_profit,
    SUM(wr.wr_return_amt)                    AS total_returns,
    inv_agg.total_quantity_on_hand,
    (SUM(cs.cs_net_profit) - SUM(wr.wr_return_amt)) AS net_gain
FROM catalog_sales cs
JOIN customer_address ca_bill
     ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN warehouse w
     ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN inv_agg
     ON w.w_warehouse_sk = inv_agg.inv_warehouse_sk
JOIN web_returns wr
     ON ca_bill.ca_address_sk = wr.wr_refunded_addr_sk
JOIN web_page wp
     ON wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE
    w.w_county IN ('Marshall County', 'Walker County')
    AND w.w_gmt_offset = -6.00
    AND ca_bill.ca_country = 'United States'
    AND wp.wp_image_count > 3
    AND wp.wp_rec_start_date >= DATE '1999-01-01'
    AND cs.cs_quantity >= 5
    AND cs.cs_net_profit > 0
GROUP BY
    w.w_warehouse_id,
    w.w_warehouse_name,
    w.w_county,
    inv_agg.total_quantity_on_hand
HAVING
    SUM(cs.cs_ext_sales_price) > 10000
ORDER BY net_gain DESC
LIMIT 100
