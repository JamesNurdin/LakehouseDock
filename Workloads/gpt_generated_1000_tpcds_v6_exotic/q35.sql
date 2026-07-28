WITH ss_agg AS (
    SELECT
        ss_customer_sk,
        ss_cdemo_sk,
        ss_hdemo_sk,
        ss_sold_date_sk,
        ss_sold_time_sk,
        SUM(ss_net_paid)      AS total_net_paid,
        SUM(ss_quantity)      AS total_qty
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 2450000 AND 2455000
    GROUP BY
        ss_customer_sk,
        ss_cdemo_sk,
        ss_hdemo_sk,
        ss_sold_date_sk,
        ss_sold_time_sk
)
SELECT
    cr.cr_returned_date_sk,
    cr_refunded_c.c_customer_id      AS refunded_customer_id,
    cr_returning_c.c_customer_id     AS returning_customer_id,
    cd_refunded.cd_gender            AS refunded_gender,
    cd_returning.cd_marital_status   AS returning_marital_status,
    hd_refunded.hd_buy_potential     AS refunded_buy_potential,
    hd_returning.hd_vehicle_count    AS returning_vehicle_count,
    ss_agg.total_net_paid            AS sales_total_net_paid,
    COUNT(*)                         AS return_count,
    SUM(cr.cr_net_loss)              AS total_net_loss
FROM catalog_returns cr
-- time of the return
JOIN time_dim t_ret
    ON cr.cr_returned_time_sk = t_ret.t_time_sk
-- refunded customer and its attributes
JOIN customer cr_refunded_c
    ON cr.cr_refunded_customer_sk = cr_refunded_c.c_customer_sk
JOIN customer_demographics cd_refunded
    ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
JOIN household_demographics hd_refunded
    ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
-- returning customer and its attributes
JOIN customer cr_returning_c
    ON cr.cr_returning_customer_sk = cr_returning_c.c_customer_sk
JOIN customer_demographics cd_returning
    ON cr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
JOIN household_demographics hd_returning
    ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
-- aggregated sales for the refunded customer
JOIN ss_agg
    ON ss_agg.ss_customer_sk = cr_refunded_c.c_customer_sk
   AND ss_agg.ss_cdemo_sk   = cd_refunded.cd_demo_sk
   AND ss_agg.ss_hdemo_sk   = hd_refunded.hd_demo_sk
-- time dimension for the sale event (second join to time_dim under a different alias)
JOIN time_dim t_sale
    ON ss_agg.ss_sold_time_sk = t_sale.t_time_sk
-- web page visits of the returning customer (left join to keep returns without a page)
LEFT JOIN web_page wp
    ON wp.wp_customer_sk = cr_returning_c.c_customer_sk
WHERE cr.cr_net_loss > 0
  AND EXISTS (
        SELECT 1
        FROM store_sales ss2
        WHERE ss2.ss_customer_sk = cr_refunded_c.c_customer_sk
          AND ss2.ss_sold_date_sk = cr.cr_returned_date_sk
    )
  AND NOT EXISTS (
        SELECT 1
        FROM web_page wp2
        WHERE wp2.wp_customer_sk = cr_refunded_c.c_customer_sk
          AND wp2.wp_type = 'Home'
    )
GROUP BY
    cr.cr_returned_date_sk,
    cr_refunded_c.c_customer_id,
    cr_returning_c.c_customer_id,
    cd_refunded.cd_gender,
    cd_returning.cd_marital_status,
    hd_refunded.hd_buy_potential,
    hd_returning.hd_vehicle_count,
    ss_agg.total_net_paid
ORDER BY total_net_loss DESC
LIMIT 100
