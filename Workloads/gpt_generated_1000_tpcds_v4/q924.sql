/*
Goal: Analyze store return performance per customer, linking returns to catalog pages, inventory levels, and promotions active on the return date. The query joins all eight selected tables (some of them multiple times under different aliases) to compute per‑customer aggregates, enrich them with catalog and promotion metadata, and compare each customer's loss to the average loss for the return reason.
*/
WITH return_data AS (
    SELECT
        sr.sr_ticket_number,
        sr.sr_returned_date_sk,
        sr.sr_return_time_sk,
        sr.sr_customer_sk,
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        c.c_salutation,
        sr.sr_reason_sk,
        sr.sr_net_loss,
        sr.sr_return_amt_inc_tax,
        sr.sr_return_quantity,
        d_ret.d_date   AS return_date,
        t.t_hour,
        r.r_reason_desc,
        r.r_reason_id
    FROM store_returns sr
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN date_dim d_ret
        ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN time_dim t
        ON sr.sr_return_time_sk = t.t_time_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
)
SELECT
    rd.c_customer_sk,
    rd.c_first_name,
    rd.c_last_name,
    rd.c_birth_year,
    rd.c_salutation,
    COUNT(DISTINCT rd.sr_ticket_number)               AS distinct_return_tickets,
    SUM(rd.sr_net_loss)                               AS total_net_loss,
    AVG(rd.sr_return_amt_inc_tax)                     AS avg_return_amount_inc_tax,
    (SELECT AVG(sr2.sr_net_loss)
       FROM store_returns sr2
       WHERE sr2.sr_reason_sk = rd.sr_reason_sk)   AS avg_loss_by_reason,
    cp.cp_catalog_number,
    inv.inv_quantity_on_hand,
    p.p_promo_name,
    d_cp_start.d_year                                 AS catalog_start_year,
    d_promo_end.d_year                                 AS promo_end_year
FROM return_data rd
JOIN catalog_page cp
    ON cp.cp_end_date_sk = rd.sr_returned_date_sk
JOIN date_dim d_cp_start
    ON cp.cp_start_date_sk = d_cp_start.d_date_sk
JOIN inventory inv
    ON inv.inv_date_sk = rd.sr_returned_date_sk
JOIN promotion p
    ON p.p_start_date_sk = rd.sr_returned_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
GROUP BY
    rd.c_customer_sk,
    rd.c_first_name,
    rd.c_last_name,
    rd.c_birth_year,
    rd.c_salutation,
    cp.cp_catalog_number,
    inv.inv_quantity_on_hand,
    p.p_promo_name,
    d_cp_start.d_year,
    d_promo_end.d_year,
    rd.sr_reason_sk
ORDER BY total_net_loss DESC
LIMIT 100
