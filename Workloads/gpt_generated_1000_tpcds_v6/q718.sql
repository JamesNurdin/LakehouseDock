WITH sales_promo AS (
    SELECT
        ss.ss_hdemo_sk,
        ss.ss_net_profit,
        ss.ss_quantity,
        ss.ss_sales_price,
        p.p_promo_sk,
        p.p_channel_details,
        regexp_extract(p.p_channel_details, '(\\w+)$', 1) AS detail_last_word,
        p.p_channel_email
    FROM tpcds.store_sales ss
    JOIN tpcds.promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    WHERE regexp_like(p.p_channel_details, '(?i)common')
      AND p.p_channel_email = 'N'
)
SELECT
    hd.hd_demo_sk,
    concat('Potential:', hd.hd_buy_potential) AS buy_potential_desc,
    sum(sp.ss_net_profit) AS total_net_profit,
    count(*) AS sales_cnt,
    max(sp.detail_last_word) AS last_word_in_detail,
    (
        SELECT count(*)
        FROM tpcds.web_returns wr
        WHERE wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
          AND wr.wr_return_amt > 10
    ) AS high_return_cnt
FROM sales_promo sp
JOIN tpcds.household_demographics hd
    ON sp.ss_hdemo_sk = hd.hd_demo_sk
WHERE hd.hd_buy_potential LIKE '0-%'
   OR hd.hd_buy_potential = '>10000'
GROUP BY hd.hd_demo_sk, hd.hd_buy_potential
HAVING sum(sp.ss_net_profit) > 1000
ORDER BY total_net_profit DESC
LIMIT 100
