WITH ss_agg AS (
    SELECT
        s.s_store_id,
        p.p_promo_id,
        td.t_hour,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    INNER JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    INNER JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    INNER JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    INNER JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    INNER JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE p.p_channel_dmail = 'Y'
      AND ca.ca_state = 'CA'
      AND td.t_hour BETWEEN 9 AND 17
      AND cd.cd_gender = 'M'
    GROUP BY ROLLUP (s.s_store_id, p.p_promo_id, td.t_hour)
),
wr_agg AS (
    SELECT
        r.r_reason_id,
        td.t_hour,
        SUM(wr.wr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt
    FROM web_returns wr
    INNER JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    INNER JOIN time_dim td
        ON wr.wr_returned_time_sk = td.t_time_sk
    INNER JOIN customer_address ca_wr
        ON wr.wr_returning_addr_sk = ca_wr.ca_address_sk
    INNER JOIN customer_demographics cd_wr
        ON wr.wr_returning_cdemo_sk = cd_wr.cd_demo_sk
    WHERE ca_wr.ca_zip LIKE '9%'
      AND r.r_reason_desc LIKE '%price%'
      AND td.t_hour BETWEEN 9 AND 17
      AND cd_wr.cd_gender = 'M'
    GROUP BY CUBE (r.r_reason_id, td.t_hour)
),
combined AS (
    SELECT
        s_store_id,
        p_promo_id,
        CAST(NULL AS varchar) AS r_reason_id,
        t_hour,
        total_sales,
        total_profit,
        sales_cnt,
        CAST(NULL AS decimal(15,2)) AS total_return_amt,
        CAST(NULL AS bigint) AS return_cnt
    FROM ss_agg
    UNION ALL
    SELECT
        CAST(NULL AS varchar) AS s_store_id,
        CAST(NULL AS varchar) AS p_promo_id,
        r_reason_id,
        t_hour,
        CAST(NULL AS decimal(15,2)) AS total_sales,
        CAST(NULL AS decimal(15,2)) AS total_profit,
        CAST(NULL AS bigint) AS sales_cnt,
        total_return_amt,
        return_cnt
    FROM wr_agg
)
SELECT
    s_store_id,
    p_promo_id,
    r_reason_id,
    t_hour,
    total_sales,
    total_profit,
    sales_cnt,
    total_return_amt,
    return_cnt,
    ROW_NUMBER() OVER (PARTITION BY t_hour ORDER BY total_profit DESC NULLS LAST) AS profit_rank,
    SUM(total_sales) OVER (PARTITION BY t_hour) AS sum_sales_per_hour
FROM combined
WHERE (
        s_store_id IS NOT NULL
        AND EXISTS (
            SELECT 1
            FROM promotion p2
            WHERE p2.p_promo_id = combined.p_promo_id
              AND p2.p_discount_active = 'Y'
        )
      )
   OR (
        r_reason_id IS NOT NULL
        AND EXISTS (
            SELECT 1
            FROM reason r2
            WHERE r2.r_reason_id = combined.r_reason_id
              AND r2.r_reason_desc LIKE '%price%'
        )
    )
ORDER BY t_hour, profit_rank
LIMIT 100
