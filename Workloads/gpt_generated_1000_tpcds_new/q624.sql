WITH base AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_addr_sk,
        sr.sr_hdemo_sk,
        sr.sr_reason_sk,
        sr.sr_customer_sk,
        sr.sr_return_amt,
        sr.sr_net_loss,
        d.d_year,
        d.d_date,
        ca.ca_state,
        ca.ca_city,
        hd.hd_buy_potential,
        hd.hd_dep_count,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        r.r_reason_desc,
        wp.wp_link_count,
        wp.wp_char_count,
        wp.wp_url,
        ws.web_name,
        ws.web_class
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
      AND ca.ca_state = 'CA'
      AND hd.hd_buy_potential = '>10000'
),
expanded AS (
    SELECT
        b.*, 
        metric
    FROM base b
    CROSS JOIN UNNEST(ARRAY[b.wp_link_count, b.wp_char_count]) AS t(metric)
),
key_excluded AS (
    SELECT sr_customer_sk
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
    EXCEPT
    SELECT sr_customer_sk
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 1999
),
key_intersect AS (
    SELECT sr_customer_sk
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
    INTERSECT
    SELECT sr_customer_sk
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2000 AND sr.sr_return_amt > 100
)
SELECT
    e.d_year,
    e.ca_state,
    e.metric,
    CASE WHEN e.metric > 10 THEN 'High' ELSE 'Low' END AS metric_level,
    e.sr_return_amt,
    RANK() OVER (PARTITION BY e.d_year, e.ca_state ORDER BY e.sr_return_amt DESC) AS return_amt_rank
FROM expanded e
WHERE e.metric > 5
  AND e.sr_customer_sk IN (SELECT sr_customer_sk FROM key_intersect)
  AND e.sr_customer_sk NOT IN (SELECT sr_customer_sk FROM key_excluded)
ORDER BY e.d_year DESC, return_amt_rank ASC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
