WITH agg AS (
    SELECT
        ws.web_name,
        d_ret.d_month_seq,
        cs.c_salutation,
        p.p_promo_name,
        COUNT(DISTINCT sr.sr_ticket_number) AS distinct_tickets,
        SUM(sr.sr_return_amt) AS total_return_amt,
        AVG(sr.sr_refunded_cash) AS avg_refunded_cash,
        MIN(sr.sr_return_quantity) AS min_return_qty,
        MAX(sr.sr_fee) AS max_fee
    FROM store_returns sr
    JOIN date_dim d_ret
        ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN customer cs
        ON sr.sr_customer_sk = cs.c_customer_sk
    JOIN promotion p
        ON p.p_start_date_sk = d_ret.d_date_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d_ret.d_date_sk
    WHERE
        d_ret.d_year = 2001
        AND cs.c_preferred_cust_flag = 'Y'
        AND p.p_discount_active = 'Y'
        AND ws.web_class = 'Unknown'
        AND sr.sr_return_amt > 10
    GROUP BY
        ws.web_name,
        d_ret.d_month_seq,
        cs.c_salutation,
        p.p_promo_name
)
SELECT
    web_name,
    d_month_seq,
    c_salutation,
    p_promo_name,
    distinct_tickets,
    total_return_amt,
    avg_refunded_cash,
    min_return_qty,
    max_fee,
    ROW_NUMBER() OVER (ORDER BY total_return_amt DESC) AS rn
FROM agg
ORDER BY rn
LIMIT 100
