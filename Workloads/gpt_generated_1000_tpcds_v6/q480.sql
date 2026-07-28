WITH base AS (
    SELECT
        i.i_item_sk,
        i.i_brand,
        i.i_manager_id,
        i.i_rec_end_date,
        p.p_promo_name,
        cd_s.cd_gender AS store_gender,
        sr.sr_return_quantity AS store_return_qty,
        sr.sr_return_amt AS store_return_amt,
        sr.sr_reversed_charge AS store_rev_charge,
        wr.wr_return_quantity AS web_return_qty,
        wr.wr_return_amt AS web_return_amt,
        wr.wr_reversed_charge AS web_rev_charge,
        wp.wp_type AS web_page_type,
        cd_r.cd_gender AS web_refunded_gender,
        cd_t.cd_gender AS web_returning_gender
    FROM store_returns sr
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    JOIN promotion p
        ON p.p_item_sk = i.i_item_sk
    JOIN customer_demographics cd_s
        ON sr.sr_cdemo_sk = cd_s.cd_demo_sk
    JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN customer_demographics cd_r
        ON wr.wr_refunded_cdemo_sk = cd_r.cd_demo_sk
    JOIN customer_demographics cd_t
        ON wr.wr_returning_cdemo_sk = cd_t.cd_demo_sk
    WHERE i.i_manager_id = 63
      AND i.i_rec_end_date = DATE '2000-10-26'
      AND sr.sr_return_amt > 100
),
agg AS (
    SELECT
        i_brand,
        store_gender,
        p_promo_name,
        COUNT(*) AS num_transactions,
        SUM(store_return_amt) AS total_store_return,
        SUM(web_return_amt) AS total_web_return,
        AVG(store_return_qty) AS avg_store_qty,
        AVG(web_return_qty) AS avg_web_qty,
        MIN(store_rev_charge) AS min_store_rev,
        MAX(web_rev_charge) AS max_web_rev
    FROM base
    GROUP BY ROLLUP (i_brand, store_gender, p_promo_name)
)
SELECT
    i_brand,
    store_gender,
    p_promo_name,
    num_transactions,
    total_store_return,
    total_web_return,
    avg_store_qty,
    avg_web_qty,
    min_store_rev,
    max_web_rev,
    SUM(total_store_return) OVER (PARTITION BY i_brand) AS brand_total_store_return,
    RANK() OVER (ORDER BY total_store_return DESC) AS brand_store_return_rank
FROM agg
ORDER BY i_brand NULLS LAST,
         store_gender NULLS LAST,
         p_promo_name NULLS LAST
LIMIT 100
