WITH sampled_store AS (
    SELECT *
    FROM store
    TABLESAMPLE BERNOULLI (10)
)
,
unioned AS (
    SELECT
        s.s_store_id                      AS store_id,
        ca.ca_state                       AS state,
        t.t_hour                          AS return_hour,
        sr.sr_return_amt_inc_tax          AS return_amount,
        (SELECT COUNT(*)
         FROM store_returns sr2
         WHERE sr2.sr_store_sk = s.s_store_sk) AS total_store_returns,
        row_number() OVER (PARTITION BY s.s_store_id ORDER BY sr.sr_return_amt_inc_tax DESC) AS rn
    FROM store_returns sr
    JOIN sampled_store s ON sr.sr_store_sk = s.s_store_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE s.s_country = 'United States'
      AND t.t_hour BETWEEN 9 AND 17

    UNION

    SELECT
        CAST(NULL AS varchar)                AS store_id,
        ca.ca_state                          AS state,
        t.t_hour                             AS return_hour,
        wr.wr_return_amt_inc_tax             AS return_amount,
        0                                     AS total_store_returns,
        row_number() OVER (PARTITION BY ca.ca_state ORDER BY wr.wr_return_amt_inc_tax DESC) AS rn
    FROM web_returns wr
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN customer_address ca ON wr.wr_returning_addr_sk = ca.ca_address_sk
    WHERE t.t_hour BETWEEN 9 AND 17
)
,
ranked AS (
    SELECT
        store_id,
        state,
        return_hour,
        return_amount,
        total_store_returns,
        rn,
        row_number() OVER (PARTITION BY store_id ORDER BY return_amount DESC) AS final_rank
    FROM unioned
    WHERE rn <= 5
)
SELECT
    store_id,
    state,
    return_hour,
    return_amount,
    total_store_returns,
    final_rank
FROM ranked
WHERE final_rank <= 5
ORDER BY store_id, final_rank
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
