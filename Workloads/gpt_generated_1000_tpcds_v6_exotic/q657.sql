WITH base AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_marital_status,
        p.p_promo_id,
        dr_return.d_year AS return_year,
        dr_sold.d_year AS sold_year,
        ws.ws_net_paid_inc_ship,
        sr.sr_net_loss
    FROM store_returns sr
    JOIN date_dim dr_return
        ON sr.sr_returned_date_sk = dr_return.d_date_sk
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN web_sales ws
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN date_dim dr_sold
        ON ws.ws_sold_date_sk = dr_sold.d_date_sk
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    WHERE dr_return.d_year = 2000
      AND dr_sold.d_year = 2000
      AND p.p_discount_active = 'Y'
      AND cd.cd_gender = 'M'
      AND hd.hd_vehicle_count >= 2
),
agg AS (
    SELECT
        c_customer_sk,
        c_first_name,
        c_last_name,
        cd_marital_status,
        p_promo_id,
        return_year,
        sold_year,
        SUM(ws_net_paid_inc_ship) AS total_net_paid,
        SUM(sr_net_loss) AS total_net_loss,
        COUNT(*) AS transaction_count
    FROM base
    GROUP BY
        c_customer_sk,
        c_first_name,
        c_last_name,
        cd_marital_status,
        p_promo_id,
        return_year,
        sold_year
    HAVING SUM(ws_net_paid_inc_ship) > 1000
)
SELECT
    c_customer_sk,
    c_first_name,
    c_last_name,
    CASE WHEN cd_marital_status = 'M' THEN 'Married' ELSE 'Other' END AS marital_status_flag,
    p_promo_id,
    return_year,
    sold_year,
    total_net_paid,
    total_net_loss,
    transaction_count,
    ROW_NUMBER() OVER (PARTITION BY p_promo_id ORDER BY total_net_paid DESC) AS promo_rank
FROM agg
ORDER BY total_net_paid DESC
LIMIT 100
