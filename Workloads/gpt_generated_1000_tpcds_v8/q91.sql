WITH sales_base AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_bill_customer_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        d_sold.d_year AS sold_year,
        sm.sm_ship_mode_id,
        i.i_item_id,
        p.p_promo_id
    FROM catalog_sales cs
    JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN customer cust_bill ON cs.cs_bill_customer_sk = cust_bill.c_customer_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE d_sold.d_year = 2001
      AND d_ship.d_year = 2001
      AND i.i_brand = 'Brand#12'
      AND p.p_discount_active = 'Y'
      AND sm.sm_type = 'AIR'
      AND cust_bill.c_preferred_cust_flag = 'N'
),
catalog_ret AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_item_sk,
        cr.cr_order_number,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cs.cs_quantity,
        cs.cs_net_paid,
        i.i_item_id,
        d.d_year AS return_year,
        cust.c_customer_sk,
        cust.c_last_name,
        cr.cr_fee
    FROM catalog_returns cr
    JOIN catalog_sales cs ON cr.cr_order_number = cs.cs_order_number
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer cust ON cr.cr_refunded_customer_sk = cust.c_customer_sk
    WHERE cr.cr_return_amount > 100
      AND cr.cr_net_loss > 0
      AND d.d_year = 2001
      AND i.i_category = 'Sports'
      AND cust.c_current_hdemo_sk IN (6247, 892)
      AND cr.cr_fee < 80
),
web_ret AS (
    SELECT
        wr.wr_returned_date_sk AS cr_returned_date_sk,
        wr.wr_item_sk AS cr_item_sk,
        NULL AS cr_order_number,
        wr.wr_return_amt AS cr_return_amount,
        wr.wr_net_loss AS cr_net_loss,
        NULL AS cs_quantity,
        NULL AS cs_net_paid,
        i.i_item_id,
        d.d_year AS return_year,
        cust.c_customer_sk,
        cust.c_last_name,
        wr.wr_fee AS cr_fee
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer cust ON wr.wr_refunded_customer_sk = cust.c_customer_sk
    WHERE wr.wr_return_amt > 100
      AND wr.wr_net_loss > 0
      AND d.d_year = 2001
      AND i.i_category = 'Sports'
      AND cust.c_current_hdemo_sk IN (6247, 892)
      AND wr.wr_fee < 80
),
unified_returns AS (
    SELECT * FROM catalog_ret
    UNION ALL
    SELECT * FROM web_ret
)
SELECT
    ur.cr_returned_date_sk,
    d_ret.d_date AS return_date,
    ur.i_item_id,
    ur.c_customer_sk,
    ur.c_last_name,
    ur.cr_return_amount,
    ur.cr_net_loss,
    COALESCE(sb.cs_quantity, 0) AS quantity_sold,
    COALESCE(sb.cs_net_paid, 0) AS net_paid,
    CASE
        WHEN ur.cr_net_loss > 500 THEN 'HIGH'
        WHEN ur.cr_net_loss > 200 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS loss_category,
    RANK() OVER (PARTITION BY ur.i_item_id ORDER BY ur.cr_net_loss DESC) AS loss_rank,
    (SELECT COUNT(*)
     FROM unified_returns ur2
     WHERE ur2.c_customer_sk = ur.c_customer_sk
       AND ur2.return_year = ur.return_year) AS customer_year_return_cnt
FROM unified_returns ur
LEFT JOIN sales_base sb
      ON ur.cr_item_sk = sb.cs_item_sk
     AND ur.c_customer_sk = sb.cs_bill_customer_sk
JOIN date_dim d_ret
      ON ur.cr_returned_date_sk = d_ret.d_date_sk
WHERE ur.return_year = 2001
  AND ur.cr_return_amount BETWEEN 100 AND 1000
  AND (CASE
        WHEN ur.cr_net_loss > 500 THEN 'HIGH'
        WHEN ur.cr_net_loss > 200 THEN 'MEDIUM'
        ELSE 'LOW'
       END) <> 'LOW'
ORDER BY loss_rank, ur.cr_return_amount DESC
LIMIT 100
