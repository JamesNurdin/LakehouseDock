WITH base AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        w.w_warehouse_name,
        p.p_promo_name,
        ws.ss_ext_sales_price,
        ws.ss_net_profit,
        cr.cr_net_loss        AS catalog_net_loss,
        sr.sr_net_loss        AS store_net_loss,
        ws.ss_quantity
    FROM store_sales ws
    JOIN date_dim d ON ws.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ws.ss_sold_time_sk = t.t_time_sk
    JOIN customer c ON ws.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ws.ss_cdemo_sk = cd.cd_demo_sk
    JOIN promotion p ON ws.ss_promo_sk = p.p_promo_sk
    JOIN store_returns sr
        ON sr.sr_item_sk = ws.ss_item_sk
        AND sr.sr_ticket_number = ws.ss_ticket_number
        AND sr.sr_returned_date_sk = d.d_date_sk
        AND sr.sr_return_time_sk = t.t_time_sk
    JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
        AND cr.cr_returned_time_sk = t.t_time_sk
        AND cr.cr_refunded_customer_sk = c.c_customer_sk
        AND cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN web_site we ON we.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND t.t_hour BETWEEN 10 AND 15
      AND w.w_country = 'United States'
      AND p.p_discount_active = 'Y'
      AND we.web_gmt_offset > 0
)
SELECT
    year,
    month_seq,
    warehouse_name,
    promo_name,
    SUM(total_sales)        AS total_sales,
    SUM(total_profit)       AS total_profit,
    SUM(total_net_loss)     AS total_net_loss,
    AVG(sales_per_quantity) AS avg_sales_per_quantity
FROM (
    SELECT
        d_year                AS year,
        d_month_seq           AS month_seq,
        w_warehouse_name      AS warehouse_name,
        p_promo_name          AS promo_name,
        ss_ext_sales_price    AS total_sales,
        ss_net_profit         AS total_profit,
        (catalog_net_loss + store_net_loss) AS total_net_loss,
        ss_ext_sales_price / NULLIF(ss_quantity, 0) AS sales_per_quantity
    FROM base
) sub
GROUP BY year, month_seq, warehouse_name, promo_name
HAVING SUM(total_sales) > 100000
ORDER BY total_sales DESC
LIMIT 100
