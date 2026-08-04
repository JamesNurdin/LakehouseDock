WITH base_returns AS (
    SELECT
        wr.wr_item_sk,
        wr.wr_returned_date_sk,
        wr.wr_return_amt,
        i.i_item_id,
        i.i_class,
        i.i_manager_id,
        i.i_brand,
        r.r_reason_id,
        r.r_reason_desc,
        d.d_year,
        d.d_month_seq,
        d.d_moy,
        d.d_date_sk
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
      AND d.d_moy BETWEEN 5 AND 9
      AND i.i_class = 'pants'
      AND i.i_manager_id IN (3, 21)
      AND r.r_reason_id = 'AAAAAAABBAAAAAA'
),
catalog_filtered AS (
    SELECT
        cp.cp_catalog_page_sk,
        cp.cp_catalog_number,
        cp.cp_type,
        cp.cp_start_date_sk,
        cp.cp_end_date_sk,
        d2.d_year AS cp_year
    FROM catalog_page cp
    JOIN date_dim d2 ON cp.cp_end_date_sk = d2.d_date_sk
    WHERE cp.cp_type = 'monthly'
      AND cp.cp_catalog_number > 10
      AND d2.d_year = 2001
),
store_filtered AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_state,
        s.s_closed_date_sk,
        s.s_geography_class
    FROM store s
    WHERE s.s_state = 'CA'
      AND s.s_geography_class = 'Unknown'
),
diff_items AS (
    SELECT DISTINCT i_item_id
    FROM base_returns
    EXCEPT
    SELECT i_item_id
    FROM item
    WHERE i_class = 'furniture'
),
union_returns AS (
    SELECT br.wr_item_sk, br.r_reason_desc
    FROM base_returns br
    WHERE br.r_reason_desc LIKE '%price%'
    UNION
    SELECT br.wr_item_sk, br.r_reason_desc
    FROM base_returns br
    WHERE br.r_reason_desc LIKE '%fit%'
),
full_joined AS (
    SELECT
        br.*, 
        sf.s_store_name,
        sf.s_state
    FROM base_returns br
    FULL OUTER JOIN store_filtered sf
        ON br.wr_returned_date_sk = sf.s_closed_date_sk
)
SELECT
    fj.wr_returned_date_sk AS return_date_key,
    fj.d_year,
    fj.i_item_id,
    fj.s_store_name,
    fj.r_reason_desc,
    CASE WHEN fj.wr_return_amt > 0 THEN 'Profit' ELSE 'Loss' END AS return_category,
    lt.total_item_return_amt,
    RANK() OVER (PARTITION BY fj.s_store_name ORDER BY fj.wr_return_amt DESC) AS rank_by_return_amt,
    cf.cp_type
FROM full_joined fj
JOIN catalog_filtered cf ON fj.wr_returned_date_sk = cf.cp_end_date_sk
CROSS JOIN LATERAL (
    SELECT SUM(br2.wr_return_amt) AS total_item_return_amt
    FROM base_returns br2
    WHERE br2.wr_item_sk = fj.wr_item_sk
) lt
WHERE fj.wr_item_sk IN (SELECT wr_item_sk FROM union_returns)
ORDER BY rank_by_return_amt ASC
LIMIT 100
