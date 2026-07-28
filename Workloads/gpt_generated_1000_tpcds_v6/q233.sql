WITH sales_agg AS (
    SELECT
        ss_store_sk,
        ss_item_sk,
        SUM(ss_quantity) AS total_quantity_sold,
        SUM(ss_ext_sales_price) AS total_sales
    FROM store_sales
    WHERE ss_list_price > 100
      AND ss_sales_price > 10
    GROUP BY ss_store_sk, ss_item_sk
)
SELECT
    s.s_store_id,
    s.s_state,
    s.s_market_manager,
    s.s_tax_percentage,
    sa.total_quantity_sold,
    sa.total_sales,
    COUNT(DISTINCT r.sr_ticket_number) AS distinct_returns,
    SUM(r.sr_net_loss) AS total_net_loss,
    CASE
        WHEN SUM(r.sr_net_loss) > 0 THEN 'LOSS'
        ELSE 'GAIN'
    END AS profit_indicator,
    SUM(r.sr_reversed_charge) AS total_reversed_charge,
    SUM(r.sr_store_credit) AS total_store_credit,
    RANK() OVER (ORDER BY sa.total_sales DESC) AS sales_rank,
    SUM(SUM(r.sr_net_loss)) OVER () AS cumulative_net_loss
FROM store s
JOIN sales_agg sa
    ON s.s_store_sk = sa.ss_store_sk
JOIN store_returns r
    ON r.sr_store_sk = s.s_store_sk
   AND r.sr_item_sk = sa.ss_item_sk
   AND r.sr_ticket_number = (
        SELECT ss_ticket_number
        FROM store_sales ss
        WHERE ss.ss_store_sk = s.s_store_sk
          AND ss.ss_item_sk = sa.ss_item_sk
        ORDER BY ss.ss_sold_date_sk DESC
        LIMIT 1
   )
WHERE s.s_state = 'CA'
  AND s.s_tax_percentage >= 0.05
  AND r.sr_reversed_charge > 30
  AND EXISTS (
        SELECT 1
        FROM store_returns r2
        WHERE r2.sr_store_sk = s.s_store_sk
          AND r2.sr_store_credit > 200
   )
GROUP BY
    s.s_store_id,
    s.s_state,
    s.s_market_manager,
    s.s_tax_percentage,
    sa.total_quantity_sold,
    sa.total_sales
ORDER BY sa.total_sales DESC
LIMIT 100
