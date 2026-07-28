WITH joined AS (
    SELECT
        cs.cs_net_paid,
        cs.cs_quantity,
        cs.cs_sold_date_sk,
        d.d_year,
        d.d_date,
        sr.sr_return_amt,
        sr.sr_returned_date_sk,
        s.s_store_name,
        s.s_state,
        r.r_reason_desc,
        w.web_company_name
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN web_site w ON w.web_open_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
      AND r.r_reason_desc LIKE '%size%'
      AND s.s_state = 'CA'
      AND w.web_company_name = 'anti'
      AND cs.cs_quantity > 5
)
SELECT
    s_store_name,
    s_state,
    d_year,
    SUM(cs_net_paid) AS total_sales,
    SUM(sr_return_amt) AS total_returns,
    SUM(cs_net_paid) - SUM(sr_return_amt) AS net_profit,
    RANK() OVER (PARTITION BY s_state ORDER BY SUM(cs_net_paid) - SUM(sr_return_amt) DESC) AS profit_rank_state
FROM joined
GROUP BY s_store_name, s_state, d_year
ORDER BY net_profit DESC
LIMIT 100
