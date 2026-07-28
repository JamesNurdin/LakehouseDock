WITH sales_agg AS (
    SELECT
        cs_item_sk,
        cs_warehouse_sk,
        cs_sold_date_sk,
        cs_bill_addr_sk,
        SUM(cs_net_paid_inc_tax) AS total_sales_net,
        COUNT(*) AS sales_cnt
    FROM catalog_sales
    WHERE cs_net_paid_inc_tax > 100
      AND cs_quantity >= 2
      AND cs_ext_discount_amt < 500
      AND cs_list_price > 500
      AND cs_wholesale_cost > 0
      AND cs_ext_tax >= 0
    GROUP BY cs_item_sk, cs_warehouse_sk, cs_sold_date_sk, cs_bill_addr_sk
),
store_ret_agg AS (
    SELECT
        sr_item_sk,
        sr_returned_date_sk,
        SUM(sr_net_loss) AS total_store_loss,
        COUNT(*) AS store_ret_cnt
    FROM store_returns
    WHERE sr_return_amt_inc_tax > 50
      AND sr_return_quantity > 0
      AND sr_fee >= 0
      AND sr_return_tax >= 0
    GROUP BY sr_item_sk, sr_returned_date_sk
)
SELECT
    i.i_manufact,
    w.w_warehouse_name,
    d_ret.d_year,
    SUM(s.total_sales_net)                     AS sum_sales_net,
    SUM(r.total_store_loss)                    AS sum_store_loss,
    COUNT(DISTINCT i.i_item_id)                AS distinct_items,
    (SUM(r.total_store_loss) / NULLIF(SUM(s.total_sales_net), 0)) * 100 AS loss_percentage
FROM sales_agg s
JOIN catalog_returns cr
    ON s.cs_item_sk = cr.cr_item_sk
   AND s.cs_warehouse_sk = cr.cr_warehouse_sk
JOIN store_ret_agg r
    ON r.sr_item_sk = cr.cr_item_sk
   AND r.sr_returned_date_sk = cr.cr_returned_date_sk
JOIN item i
    ON i.i_item_sk = s.cs_item_sk
JOIN warehouse w
    ON w.w_warehouse_sk = s.cs_warehouse_sk
JOIN date_dim d_ret
    ON d_ret.d_date_sk = cr.cr_returned_date_sk
JOIN date_dim d_sold
    ON d_sold.d_date_sk = s.cs_sold_date_sk
JOIN time_dim t
    ON t.t_time_sk = cr.cr_returned_time_sk
JOIN customer_address ca
    ON ca.ca_address_sk = s.cs_bill_addr_sk
WHERE d_ret.d_year = 2001
  AND d_sold.d_year = 2001
  AND t.t_hour BETWEEN 9 AND 17
  AND w.w_state = 'CA'
  AND i.i_brand = 'barprically'
  AND cr.cr_return_quantity > 0
  AND ca.ca_state = 'CA'
  AND NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_item_sk = i.i_item_sk
          AND cr2.cr_net_loss = 0
    )
GROUP BY i.i_manufact, w.w_warehouse_name, d_ret.d_year
HAVING SUM(r.total_store_loss) > 500
ORDER BY loss_percentage DESC
LIMIT 100
