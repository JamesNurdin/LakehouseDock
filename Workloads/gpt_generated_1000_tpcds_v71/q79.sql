-- Goal: Compute average net loss of store returns per state and price segment, ranking states by this metric while filtering on customer demographics, catalog type, item brand, store location, time of day and web page type.
WITH joined AS (
    SELECT
        s.s_store_id,
        s.s_state,
        i.i_category,
        i.i_brand,
        c.c_birth_country,
        cp.cp_type,
        cp.cp_catalog_number,
        ws.web_name,
        sr.sr_return_amt,
        sr.sr_net_loss,
        d_ret.d_year,
        d_ret.d_month_seq,
        t.t_hour,
        CASE
            WHEN i.i_current_price > 100 THEN 'expensive'
            WHEN i.i_current_price BETWEEN 50 AND 100 THEN 'mid'
            ELSE 'budget'
        END AS price_segment,
        (SELECT COUNT(*) FROM store_returns sr2 WHERE sr2.sr_item_sk = i.i_item_sk) AS item_return_cnt
    FROM store_returns sr
    JOIN date_dim d_ret
        ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN catalog_page cp
        ON cp.cp_start_date_sk = d_ret.d_date_sk
        AND cp.cp_end_date_sk = d_ret.d_date_sk
    JOIN time_dim t
        ON sr.sr_return_time_sk = t.t_time_sk
    JOIN web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
        AND wp.wp_creation_date_sk = d_ret.d_date_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d_ret.d_date_sk
        AND ws.web_close_date_sk = d_ret.d_date_sk
    WHERE c.c_birth_country IN ('GAMBIA','PHILIPPINES','BAHAMAS','UKRAINE','TOGO')
      AND cp.cp_type = 'monthly'
      AND d_ret.d_year = 2000
      AND i.i_brand_id IN (1,2,3,4)
      AND s.s_state = 'TX'
      AND t.t_hour BETWEEN 9 AND 17
      AND wp.wp_type = 'content'
),
agg_store_item AS (
    SELECT
        s_store_id,
        s_state,
        i_category,
        price_segment,
        SUM(sr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        AVG(sr_return_amt) AS avg_return_amt
    FROM joined
    GROUP BY s_store_id, s_state, i_category, price_segment
    HAVING SUM(sr_net_loss) > 0
),
final AS (
    SELECT
        s_state,
        price_segment,
        AVG(total_net_loss) AS avg_state_net_loss,
        SUM(return_cnt) AS total_returns,
        RANK() OVER (PARTITION BY s_state ORDER BY AVG(total_net_loss) DESC) AS state_rank,
        COUNT(*) AS store_categories
    FROM agg_store_item
    GROUP BY s_state, price_segment
    HAVING SUM(return_cnt) >= 10
)
SELECT *
FROM final
ORDER BY avg_state_net_loss DESC
LIMIT 100
