WITH base AS (
    SELECT
        d.d_year,
        c.c_customer_id,
        cc.cc_name,
        w.web_name,
        r.r_reason_desc,
        sr.sr_return_amt,
        sr.sr_net_loss,
        sr.sr_return_quantity,
        i.inv_quantity_on_hand,
        t.t_hour,
        ca.ca_country
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN inventory i ON i.inv_date_sk = d.d_date_sk
    JOIN call_center cc ON cc.cc_open_date_sk = d.d_date_sk
    JOIN web_site w ON w.web_open_date_sk = d.d_date_sk
    WHERE ca.ca_country = 'United States'
      AND d.d_year BETWEEN 2000 AND 2002
      AND t.t_hour BETWEEN 9 AND 17
      AND i.inv_quantity_on_hand > 100
),
agg AS (
    SELECT
        d_year,
        c_customer_id,
        cc_name,
        web_name,
        SUM(sr_return_amt) AS total_return_amt,
        SUM(sr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        SUM(CASE WHEN r_reason_desc = 'Damaged' THEN 1 ELSE 0 END) AS damaged_cnt
    FROM base
    GROUP BY d_year, c_customer_id, cc_name, web_name
)
SELECT
    d_year,
    c_customer_id,
    cc_name,
    web_name,
    total_return_amt,
    total_net_loss,
    return_cnt,
    damaged_cnt,
    RANK() OVER (PARTITION BY d_year ORDER BY total_return_amt DESC) AS revenue_rank
FROM agg
ORDER BY d_year, revenue_rank
LIMIT 100
