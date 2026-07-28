WITH filtered_returns AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_return_amt,
        sr.sr_fee,
        sr.sr_net_loss,
        s.s_store_id,
        s.s_store_name,
        d_ret.d_year
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
    WHERE regexp_like(s.s_street_name, 'Hill|Mill')
      AND s.s_suite_number LIKE 'Suite %'
),
joined_data AS (
    SELECT
        fr.s_store_id,
        fr.s_store_name,
        fr.d_year,
        fr.sr_return_amt,
        fr.sr_fee,
        fr.sr_net_loss,
        ws.web_site_id,
        ws.web_name
    FROM filtered_returns fr
    CROSS JOIN web_site ws
    JOIN date_dim d_open ON ws.web_open_date_sk = d_open.d_date_sk
        AND d_open.d_year = fr.d_year
)
SELECT
    web_site_id,
    web_name,
    regexp_extract(web_name, '(\\w+)') AS web_first_word,
    s_store_id,
    s_store_name,
    d_year,
    SUM(sr_return_amt) AS total_return_amount,
    SUM(sr_fee) AS total_fee,
    SUM(sr_net_loss) AS total_net_loss,
    CONCAT(s_store_name, ' - ', web_name) AS combined_name,
    CASE WHEN web_name LIKE '%Online%' THEN 'Online' ELSE 'Other' END AS web_type
FROM joined_data
GROUP BY GROUPING SETS (
    (web_site_id, web_name, s_store_id, s_store_name, d_year),
    (web_site_id, web_name, d_year),
    (s_store_id, s_store_name, d_year),
    (d_year),
    ()
)
ORDER BY total_return_amount DESC
LIMIT 100
