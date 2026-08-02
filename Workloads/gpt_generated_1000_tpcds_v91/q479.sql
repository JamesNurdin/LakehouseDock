WITH cs_agg AS (
    SELECT
        cs_item_sk,
        cs_sold_date_sk,
        cs_warehouse_sk,
        SUM(cs_ext_sales_price) AS total_sales,
        SUM(cs_net_profit) AS total_profit,
        COUNT(*) AS order_cnt
    FROM catalog_sales
    WHERE cs_quantity > 5
      AND cs_net_paid > 0
    GROUP BY cs_item_sk, cs_sold_date_sk, cs_warehouse_sk
),
sr_full AS (
    SELECT
        sr.sr_item_sk,
        sr.sr_store_sk,
        sr.sr_reason_sk,
        sr.sr_addr_sk,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_net_loss,
        d_ret.d_date_sk   AS return_date_sk,
        d_ret.d_year      AS return_year,
        d_ret.d_month_seq AS return_month_seq,
        d_ret.d_day_name  AS return_day_name
    FROM store_returns sr
    FULL OUTER JOIN date_dim d_ret
        ON sr.sr_returned_date_sk = d_ret.d_date_sk
),
ws_sample AS (
    SELECT
        ws_item_sk,
        ws_sold_date_sk,
        ws_warehouse_sk,
        ws_bill_addr_sk,
        ws_ext_sales_price,
        ws_net_paid,
        ws_list_price
    FROM web_sales TABLESAMPLE BERNOULLI (10)
)
SELECT
    i.i_category,
    i.i_brand,
    d_sold.d_year,
    s.s_state,
    r.r_reason_desc,
    SUM(cs_agg.total_sales)               AS total_catalog_sales,
    SUM(cs_agg.total_profit)              AS total_catalog_profit,
    SUM(ws_sample.ws_ext_sales_price)      AS total_web_sales,
    SUM(ws_sample.ws_net_paid)             AS total_web_net_paid,
    COUNT(DISTINCT i.i_item_sk)            AS distinct_items_sold,
    MAX(cs_agg.total_sales)               AS max_catalog_sales_per_item,
    MIN(ws_sample.ws_ext_sales_price)     AS min_web_sales_price
FROM cs_agg
INNER JOIN item i
    ON cs_agg.cs_item_sk = i.i_item_sk
INNER JOIN date_dim d_sold
    ON cs_agg.cs_sold_date_sk = d_sold.d_date_sk
INNER JOIN warehouse w1
    ON cs_agg.cs_warehouse_sk = w1.w_warehouse_sk
LEFT JOIN sr_full
    ON cs_agg.cs_item_sk = sr_full.sr_item_sk
LEFT JOIN reason r
    ON sr_full.sr_reason_sk = r.r_reason_sk
LEFT JOIN store s
    ON sr_full.sr_store_sk = s.s_store_sk
LEFT JOIN customer_address ca_sr
    ON sr_full.sr_addr_sk = ca_sr.ca_address_sk
INNER JOIN ws_sample
    ON i.i_item_sk = ws_sample.ws_item_sk
INNER JOIN date_dim d_ws
    ON ws_sample.ws_sold_date_sk = d_ws.d_date_sk
INNER JOIN warehouse w2
    ON ws_sample.ws_warehouse_sk = w2.w_warehouse_sk
INNER JOIN customer_address ca_ws
    ON ws_sample.ws_bill_addr_sk = ca_ws.ca_address_sk
INNER JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
WHERE i.i_category = 'Sports'
  AND i.i_brand = 'Brand#12'
  AND d_sold.d_year = 2001
  AND ca_sr.ca_state = 'CA'
  AND ws_sample.ws_list_price > 100.00
  AND w1.w_gmt_offset = -5.00
  AND cs_agg.total_sales > (SELECT AVG(cs_ext_sales_price) FROM catalog_sales)
  AND EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_item_sk = i.i_item_sk
          AND sr2.sr_return_quantity > 0
    )
GROUP BY
    i.i_category,
    i.i_brand,
    d_sold.d_year,
    s.s_state,
    r.r_reason_desc
ORDER BY total_catalog_sales DESC
LIMIT 100
