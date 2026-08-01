WITH
store_sales_agg AS (
    SELECT
        ss_item_sk,
        ss_sold_date_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(ss_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM store_sales
    WHERE ss_ext_sales_price > 1000
      AND ss_quantity >= 1
      AND ss_hdemo_sk IN (2034, 6045)
    GROUP BY ss_item_sk, ss_sold_date_sk
),
catalog_sales_agg AS (
    SELECT
        cs_item_sk,
        cs_warehouse_sk,
        cs_bill_addr_sk,
        SUM(cs_ext_sales_price) AS total_catalog_sales,
        SUM(cs_net_profit) AS total_catalog_profit,
        COUNT(*) AS catalog_cnt
    FROM catalog_sales
    WHERE cs_ext_sales_price > 500
      AND cs_quantity >= 1
      AND cs_promo_sk IS NOT NULL
    GROUP BY cs_item_sk, cs_warehouse_sk, cs_bill_addr_sk
),
store_returns_agg AS (
    SELECT
        sr_item_sk,
        sr_returned_date_sk,
        SUM(sr_return_amt) AS total_store_return_amt,
        SUM(sr_net_loss) AS total_store_return_loss,
        COUNT(*) AS store_return_cnt
    FROM store_returns
    WHERE sr_return_amt > 50
      AND sr_return_quantity > 0
    GROUP BY sr_item_sk, sr_returned_date_sk
),
web_returns_agg AS (
    SELECT
        wr_item_sk,
        wr_returned_date_sk,
        SUM(wr_return_amt) AS total_web_return_amt,
        SUM(wr_net_loss) AS total_web_return_loss,
        COUNT(*) AS web_return_cnt
    FROM web_returns
    WHERE wr_return_amt > 100
      AND wr_return_quantity > 0
    GROUP BY wr_item_sk, wr_returned_date_sk
),
combined_items AS (
    SELECT i_item_sk FROM (
        SELECT ss_item_sk AS i_item_sk FROM store_sales WHERE ss_quantity > 0
        UNION
        SELECT cs_item_sk AS i_item_sk FROM catalog_sales WHERE cs_quantity > 0
    )
)
SELECT DISTINCT
    i.i_item_id,
    i.i_item_desc,
    i.i_color,
    i.i_formulation,
    i.i_manufact_id,
    d.d_date,
    d.d_year,
    w.w_warehouse_name,
    ca.ca_city,
    ss.total_sales,
    ss.total_profit,
    ss.sales_cnt,
    cs.total_catalog_sales,
    cs.total_catalog_profit,
    cs.catalog_cnt,
    sr.total_store_return_amt,
    sr.total_store_return_loss,
    sr.store_return_cnt,
    wr.total_web_return_amt,
    wr.total_web_return_loss,
    wr.web_return_cnt,
    (SELECT AVG(total_sales)
     FROM store_sales_agg
     WHERE ss_sold_date_sk = d.d_date_sk) AS avg_sales_same_day,
    CASE WHEN EXISTS (SELECT 1
                      FROM web_returns_agg wra
                      WHERE wra.wr_item_sk = i.i_item_sk) THEN 'Y' ELSE 'N' END AS has_web_return
FROM store_sales_agg ss
JOIN date_dim d
    ON ss.ss_sold_date_sk = d.d_date_sk
JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
JOIN catalog_sales_agg cs
    ON i.i_item_sk = cs.cs_item_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
LEFT JOIN store_returns_agg sr
    ON sr.sr_item_sk = ss.ss_item_sk
   AND sr.sr_returned_date_sk = d.d_date_sk
LEFT JOIN web_returns_agg wr
    ON wr.wr_item_sk = i.i_item_sk
   AND wr.wr_returned_date_sk = d.d_date_sk
WHERE d.d_year = 2000
  AND i.i_color = 'snow'
  AND i.i_manufact_id IN (630, 52)
  AND w.w_state = 'CA'
  AND ca.ca_gmt_offset BETWEEN -8.00 AND -5.00
  AND ss.total_sales > 5000
  AND cs.total_catalog_sales > 3000
  AND i.i_item_sk IN (SELECT i_item_sk FROM combined_items)
  AND d.d_date >= DATE '2000-01-01'
  AND d.d_date <= DATE '2000-12-31'
ORDER BY ss.total_sales DESC
LIMIT 100
