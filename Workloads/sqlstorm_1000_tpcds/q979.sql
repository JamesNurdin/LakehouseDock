WITH
sales_combined AS (
    SELECT 'store' AS sales_channel,
           ss.ss_ticket_number AS order_number,
           ss.ss_customer_sk AS customer_sk,
           ss.ss_sold_date_sk AS date_sk,
           ss.ss_net_paid AS net_paid,
           ss.ss_net_profit AS net_profit,
           ss.ss_quantity AS quantity,
           ss.ss_ext_discount_amt AS discount_amt,
           ss.ss_coupon_amt AS coupon_amt,
           ss.ss_ext_sales_price AS ext_sales_price,
           ss.ss_item_sk AS item_sk
    FROM store_sales ss

    UNION ALL

    SELECT 'catalog' AS sales_channel,
           cs.cs_order_number AS order_number,
           cs.cs_bill_customer_sk AS customer_sk,
           cs.cs_sold_date_sk AS date_sk,
           cs.cs_net_paid AS net_paid,
           cs.cs_net_profit AS net_profit,
           cs.cs_quantity AS quantity,
           cs.cs_ext_discount_amt AS discount_amt,
           cs.cs_coupon_amt AS coupon_amt,
           cs.cs_ext_sales_price AS ext_sales_price,
           cs.cs_item_sk AS item_sk
    FROM catalog_sales cs

    UNION ALL

    SELECT 'web' AS sales_channel,
           ws.ws_order_number AS order_number,
           ws.ws_bill_customer_sk AS customer_sk,
           ws.ws_sold_date_sk AS date_sk,
           ws.ws_net_paid AS net_paid,
           ws.ws_net_profit AS net_profit,
           ws.ws_quantity AS quantity,
           ws.ws_ext_discount_amt AS discount_amt,
           ws.ws_coupon_amt AS coupon_amt,
           ws.ws_ext_sales_price AS ext_sales_price,
           ws.ws_item_sk AS item_sk
    FROM web_sales ws
),
returns_combined AS (
    SELECT 'store' AS sales_channel,
           sr.sr_ticket_number AS order_number,
           sr.sr_customer_sk AS customer_sk,
           sr.sr_returned_date_sk AS date_sk,
           sr.sr_return_amt_inc_tax AS return_amount,
           sr.sr_net_loss AS net_loss,
           sr.sr_return_quantity AS return_quantity
    FROM store_returns sr

    UNION ALL

    SELECT 'catalog' AS sales_channel,
           cr.cr_order_number AS order_number,
           cr.cr_refunded_customer_sk AS customer_sk,
           cr.cr_returned_date_sk AS date_sk,
           cr.cr_return_amt_inc_tax AS return_amount,
           cr.cr_net_loss AS net_loss,
           cr.cr_return_quantity AS return_quantity
    FROM catalog_returns cr

    UNION ALL

    SELECT 'web' AS sales_channel,
           wr.wr_order_number AS order_number,
           wr.wr_refunded_customer_sk AS customer_sk,
           wr.wr_returned_date_sk AS date_sk,
           wr.wr_return_amt_inc_tax AS return_amount,
           wr.wr_net_loss AS net_loss,
           wr.wr_return_quantity AS return_quantity
    FROM web_returns wr
),
latest_sales AS (
    SELECT customer_sk,
           MAX(date_sk) AS latest_sales_date_sk
    FROM sales_combined
    GROUP BY customer_sk
),
customer_sales_agg AS (
    SELECT sc.sales_channel,
           sc.customer_sk,
           COUNT(*) AS orders_cnt,
           SUM(sc.net_paid) AS total_net_paid,
           SUM(sc.net_profit) AS total_net_profit,
           SUM(sc.ext_sales_price) AS total_ext_sales,
           SUM(sc.discount_amt) AS total_discount,
           SUM(sc.coupon_amt) AS total_coupon,
           MAX(sc.date_sk) AS max_sales_date_sk
    FROM sales_combined sc
    GROUP BY sc.sales_channel, sc.customer_sk
),
customer_returns_agg AS (
    SELECT rc.sales_channel,
           rc.customer_sk,
           COUNT(*) AS returns_cnt,
           SUM(rc.return_amount) AS total_return_amount,
           SUM(rc.net_loss) AS total_return_loss,
           SUM(rc.return_quantity) AS total_return_qty,
           MAX(rc.date_sk) AS max_return_date_sk
    FROM returns_combined rc
    GROUP BY rc.sales_channel, rc.customer_sk
),
customer_full_agg AS (
    SELECT COALESCE(s.sales_channel, r.sales_channel) AS sales_channel,
           COALESCE(s.customer_sk, r.customer_sk) AS customer_sk,
           COALESCE(s.orders_cnt, 0) AS orders_cnt,
           COALESCE(s.total_net_paid, 0) AS total_net_paid,
           COALESCE(s.total_net_profit, 0) AS total_net_profit,
           COALESCE(s.total_ext_sales, 0) AS total_ext_sales,
           COALESCE(s.total_discount, 0) AS total_discount,
           COALESCE(s.total_coupon, 0) AS total_coupon,
           COALESCE(r.returns_cnt, 0) AS returns_cnt,
           COALESCE(r.total_return_amount, 0) AS total_return_amount,
           COALESCE(r.total_return_loss, 0) AS total_return_loss,
           COALESCE(r.total_return_qty, 0) AS total_return_qty,
           GREATEST(COALESCE(s.max_sales_date_sk, -1), COALESCE(r.max_return_date_sk, -1)) AS latest_activity_date_sk
    FROM customer_sales_agg s
    FULL OUTER JOIN customer_returns_agg r
      ON s.sales_channel = r.sales_channel
     AND s.customer_sk = r.customer_sk
),
customers_with_info AS (
    SELECT
        c.c_customer_sk,
        COALESCE(TRIM(c.c_first_name) || ' ' || TRIM(c.c_last_name), 'UNKNOWN') AS full_name,
        c.c_birth_year,
        cd.cd_gender,
        cd.cd_education_status,
        dm.d_date AS latest_activity_date,
        CASE
            WHEN cf.total_net_profit > 0 AND cf.returns_cnt = 0 THEN 'PROFIT_NO_RETURNS'
            WHEN cf.total_net_profit > 0 AND cf.returns_cnt > 0 THEN 'PROFIT_WITH_RETURNS'
            ELSE 'NO_PROFIT'
        END AS profit_status,
        cf.sales_channel,
        cf.orders_cnt,
        cf.total_net_paid,
        cf.total_net_profit,
        cf.total_return_amount,
        cf.total_return_loss,
        cf.total_return_qty,
        COALESCE(cf.total_net_profit - cf.total_return_loss, cf.total_net_profit) AS net_effect,
        RANK() OVER (PARTITION BY cf.sales_channel ORDER BY cf.total_net_profit DESC) AS profit_rank,
        ROUND(100.0 * cf.total_net_profit / NULLIF(SUM(cf.total_net_profit) OVER (PARTITION BY cf.sales_channel), 0), 2) AS profit_pct_of_channel,
        (SELECT COUNT(DISTINCT sc.item_sk)
           FROM sales_combined sc
          WHERE sc.customer_sk = cf.customer_sk
            AND sc.quantity > 5) AS distinct_high_qty_items,
        TRY_CAST(CONCAT('2021-02-', LPAD(CAST(mod(cf.latest_activity_date_sk, 31) + 1 AS VARCHAR), 2, '0')) AS DATE) AS derived_date,
        CASE WHEN cf.total_return_amount IS NULL THEN 0 ELSE cf.total_return_amount END AS return_amount_coalesced,
        cf.latest_activity_date_sk
    FROM customer_full_agg cf
    LEFT JOIN customer c ON cf.customer_sk = c.c_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN date_dim dm ON cf.latest_activity_date_sk = dm.d_date_sk
)
SELECT *
FROM customers_with_info
WHERE profit_status = 'PROFIT_NO_RETURNS'
UNION ALL
SELECT *
FROM customers_with_info
WHERE profit_status = 'PROFIT_WITH_RETURNS'
INTERSECT
SELECT *
FROM customers_with_info
WHERE profit_status != 'NO_PROFIT'
