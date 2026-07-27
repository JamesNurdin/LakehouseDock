WITH base AS (
    SELECT
        d.d_date,
        d.d_year,
        d.d_weekend,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ss.ss_ticket_number,
        ss.ss_net_paid,
        ss.ss_net_profit,
        sr.sr_net_loss,
        cr.cr_return_amount,
        cp.cp_type,
        inv.inv_quantity_on_hand,
        ws.web_name
    FROM tpcds.date_dim d
    JOIN tpcds.store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN tpcds.store_returns sr
        ON sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
    JOIN tpcds.catalog_page cp
        ON cp.cp_start_date_sk = d.d_date_sk
    JOIN tpcds.catalog_returns cr
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        AND cr.cr_returned_date_sk = d.d_date_sk
    JOIN tpcds.inventory inv
        ON inv.inv_date_sk = d.d_date_sk
    JOIN tpcds.web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_weekend = 'N'
      AND d.d_year = 2000
      AND sr.sr_fee > 20
      AND cp.cp_type = 'PROMO'
      AND inv.inv_quantity_on_hand > 0
),
agg_customer AS (
    SELECT
        c_customer_id,
        SUM(ss_net_paid) AS total_net_paid,
        SUM(ss_net_profit) AS total_profit,
        SUM(sr_net_loss) AS total_return_loss,
        AVG(cr_return_amount) AS avg_return_amount
    FROM base
    GROUP BY c_customer_id
)
SELECT
    a.c_customer_id,
    a.total_net_paid,
    a.total_profit,
    a.total_return_loss,
    a.avg_return_amount
FROM agg_customer a
WHERE a.total_profit > (SELECT AVG(total_profit) FROM agg_customer)
  AND a.total_return_loss < 5000
ORDER BY a.total_profit DESC
LIMIT 100
