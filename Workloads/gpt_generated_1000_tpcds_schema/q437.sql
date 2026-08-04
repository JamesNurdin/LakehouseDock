WITH sales_keys AS (
    SELECT i.i_category,
           p.p_channel_email
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE p.p_channel_email = 'N'
      AND EXISTS (
          SELECT 1
          FROM time_dim td
          WHERE td.t_time_sk = ss.ss_sold_time_sk
            AND td.t_hour = 12
      )
),
return_keys AS (
    SELECT i.i_category,
           p.p_channel_email
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN promotion p ON p.p_item_sk = i.i_item_sk
    WHERE p.p_channel_email = 'N'
),
 diff_keys AS (
    SELECT * FROM sales_keys
    EXCEPT
    SELECT * FROM return_keys
)
SELECT
    dk.i_category,
    dk.p_channel_email,
    COUNT(*) AS cnt,
    (
        SELECT COALESCE(SUM(wr2.wr_return_amt), 0)
        FROM web_returns wr2
        JOIN item i2 ON wr2.wr_item_sk = i2.i_item_sk
        WHERE i2.i_category = dk.i_category
    ) AS total_return_amount
FROM diff_keys dk
GROUP BY CUBE (dk.i_category, dk.p_channel_email)
ORDER BY cnt DESC
LIMIT 100
