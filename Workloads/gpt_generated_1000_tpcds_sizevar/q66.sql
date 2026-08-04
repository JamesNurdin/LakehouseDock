WITH base AS (
    SELECT
        p.p_promo_name,
        d_ss.d_year AS year,
        ss.ss_ticket_number,
        ss.ss_net_paid,
        ws.ws_net_paid,
        cs.cs_net_paid,
        sr.sr_return_quantity,
        i.inv_quantity_on_hand,
        p.p_promo_sk
    FROM store_sales ss
    JOIN date_dim d_ss
      ON ss.ss_sold_date_sk = d_ss.d_date_sk
    JOIN customer c
      ON ss.ss_customer_sk = c.c_customer_sk
    JOIN promotion p
      ON ss.ss_promo_sk = p.p_promo_sk
    JOIN store_returns sr
      ON sr.sr_ticket_number = ss.ss_ticket_number
     AND sr.sr_customer_sk = c.c_customer_sk
     AND sr.sr_item_sk = ss.ss_item_sk
    JOIN date_dim d_sr
      ON sr.sr_returned_date_sk = d_sr.d_date_sk
    JOIN catalog_sales cs
      ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN date_dim d_cs
      ON cs.cs_sold_date_sk = d_cs.d_date_sk
    JOIN web_sales ws
      ON ws.ws_bill_customer_sk = c.c_customer_sk
     AND ws.ws_promo_sk = p.p_promo_sk
    JOIN date_dim d_ws
      ON ws.ws_sold_date_sk = d_ws.d_date_sk
    JOIN inventory i
      ON i.inv_date_sk = d_ss.d_date_sk
    WHERE d_ss.d_year = 2002
      AND d_ws.d_year = 2002
      AND d_cs.d_year = 2002
      AND p.p_channel_tv = 'N'
      AND i.inv_quantity_on_hand > 500
      AND cs.cs_net_paid > 100
      AND ws.ws_net_paid > 100
      AND cs.cs_ext_discount_amt > 0
      AND ws.ws_coupon_amt = 0
      AND i.inv_warehouse_sk IN (12,15)
      AND p.p_discount_active = 'Y'
),
agg AS (
    SELECT
        p_promo_name,
        year,
        sum(ss_net_paid) AS sum_store_sales,
        sum(ws_net_paid) AS sum_web_sales,
        sum(cs_net_paid) AS sum_catalog_sales,
        sum(sr_return_quantity) AS total_returns,
        count(*) AS txn_cnt,
        p_promo_sk
    FROM base
    GROUP BY p_promo_name, year, p_promo_sk
)
SELECT *
FROM (
    SELECT
        a.p_promo_name,
        a.year,
        a.sum_store_sales,
        a.sum_web_sales,
        a.sum_catalog_sales,
        a.total_returns,
        a.txn_cnt,
        (SELECT sum(cs2.cs_ext_sales_price)
         FROM catalog_sales cs2
         WHERE cs2.cs_promo_sk = a.p_promo_sk) AS promo_catalog_ext_sales,
        rank() OVER (PARTITION BY a.year ORDER BY a.sum_store_sales DESC) AS rnk
    FROM agg a
    WHERE EXISTS (
        SELECT 1
        FROM store_returns sr2
        JOIN store_sales ss2 ON sr2.sr_ticket_number = ss2.ss_ticket_number
        JOIN promotion p2 ON ss2.ss_promo_sk = p2.p_promo_sk
        WHERE p2.p_promo_name = a.p_promo_name
          AND sr2.sr_return_quantity > 0
    )
) t
WHERE rnk <= 3
ORDER BY year DESC, sum_store_sales DESC
LIMIT 100
