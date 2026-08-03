WITH
store_sales_agg AS (
    SELECT
        ss_item_sk,
        SUM(ss_ext_sales_price) AS store_sales_amount,
        SUM(ss_net_profit) AS store_net_profit,
        COUNT(*) AS store_sales_cnt
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 2450815 AND 2451081
      AND ss_list_price > 20
      AND ss_coupon_amt < 200
    GROUP BY ss_item_sk
),
catalog_sales_agg AS (
    SELECT
        cs_item_sk,
        SUM(cs_ext_sales_price) AS catalog_sales_amount,
        SUM(cs_net_profit) AS catalog_net_profit,
        MIN(cs_bill_addr_sk) AS sample_bill_addr_sk
    FROM catalog_sales
    WHERE cs_sold_date_sk BETWEEN 2450815 AND 2451081
      AND cs_ext_list_price > 500
      AND cs_coupon_amt < 5000
    GROUP BY cs_item_sk
),
store_returns_agg AS (
    SELECT
        sr_item_sk,
        SUM(sr_return_amt) AS store_return_amount,
        COUNT(*) AS store_return_cnt,
        MIN(sr_addr_sk) AS sample_return_addr_sk
    FROM store_returns
    WHERE sr_returned_date_sk BETWEEN 2450815 AND 2451081
      AND sr_return_quantity > 0
      AND sr_fee < 100
    GROUP BY sr_item_sk
),
web_returns_agg AS (
    SELECT
        wr_item_sk,
        SUM(wr_return_amt) AS web_return_amount,
        COUNT(*) AS web_return_cnt,
        MIN(wr_refunded_addr_sk) AS sample_refunded_addr_sk
    FROM web_returns
    WHERE wr_returned_date_sk BETWEEN 2450815 AND 2451081
      AND wr_return_quantity > 0
      AND wr_fee < 100
    GROUP BY wr_item_sk
),
inventory_latest AS (
    SELECT
        inv_item_sk,
        MAX(inv_date_sk) AS latest_date_sk,
        SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory
    GROUP BY inv_item_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    i.i_category,
    i.i_brand,
    ss_agg.store_sales_amount,
    cs_agg.catalog_sales_amount,
    COALESCE(sr_agg.store_return_amount, 0) AS store_return_amount,
    COALESCE(wr_agg.web_return_amount, 0) AS web_return_amount,
    (ss_agg.store_net_profit + cs_agg.catalog_net_profit
        - COALESCE(sr_agg.store_return_amount, 0)
        - COALESCE(wr_agg.web_return_amount, 0)) AS total_net_profit,
    CASE
        WHEN (ss_agg.store_net_profit + cs_agg.catalog_net_profit
              - COALESCE(sr_agg.store_return_amount, 0)
              - COALESCE(wr_agg.web_return_amount, 0)) > 10000 THEN 'High'
        ELSE 'Low'
    END AS profit_category,
    CASE
        WHEN (ss_agg.store_net_profit + cs_agg.catalog_net_profit
              - COALESCE(sr_agg.store_return_amount, 0)
              - COALESCE(wr_agg.web_return_amount, 0))
             > (SELECT AVG(cs_ext_sales_price) FROM catalog_sales) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS profit_vs_global_avg,
    inv_latest.total_on_hand,
    ca_bill.ca_state AS bill_state,
    ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY (ss_agg.store_net_profit + cs_agg.catalog_net_profit
              - COALESCE(sr_agg.store_return_amount, 0)
              - COALESCE(wr_agg.web_return_amount, 0)) DESC) AS category_rank,
    v.flag
FROM item i
LEFT JOIN store_sales_agg ss_agg
    ON i.i_item_sk = ss_agg.ss_item_sk
LEFT JOIN catalog_sales_agg cs_agg
    ON i.i_item_sk = cs_agg.cs_item_sk
LEFT JOIN store_returns_agg sr_agg
    ON i.i_item_sk = sr_agg.sr_item_sk
LEFT JOIN web_returns_agg wr_agg
    ON i.i_item_sk = wr_agg.wr_item_sk
LEFT JOIN inventory_latest inv_latest
    ON i.i_item_sk = inv_latest.inv_item_sk
LEFT JOIN customer_address ca_bill
    ON cs_agg.sample_bill_addr_sk = ca_bill.ca_address_sk
LEFT JOIN customer_address ca_return
    ON sr_agg.sample_return_addr_sk = ca_return.ca_address_sk
CROSS JOIN (VALUES 'X', 'Y') AS v(flag)
WHERE i.i_current_price > 10
  AND i.i_color IS NOT NULL
  AND i.i_size <> ''
ORDER BY total_net_profit DESC
LIMIT 100
