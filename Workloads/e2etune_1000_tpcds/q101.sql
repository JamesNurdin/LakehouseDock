SELECT
    cs.cs_promo_sk AS promo_id,
    cs.cs_sold_date_sk AS sold_date_sk,
    COUNT(DISTINCT cs.cs_order_number) AS num_orders,
    SUM(cs.cs_net_paid_inc_ship_tax) AS total_sales,
    COALESCE(SUM(wr.wr_return_amt_inc_tax), 0) AS total_returns,
    SUM(cs.cs_net_profit) - COALESCE(SUM(wr.wr_net_loss), 0) AS net_profit,
    SUM(cs.cs_ext_discount_amt) / NULLIF(SUM(cs.cs_ext_list_price), 0) AS avg_discount_rate,
    (SUM(cs.cs_net_profit) - COALESCE(SUM(wr.wr_net_loss), 0)) / NULLIF(SUM(cs.cs_net_paid_inc_ship_tax) - COALESCE(SUM(wr.wr_return_amt_inc_tax), 0), 0) AS profit_margin,
    st.total_stores,
    RANK() OVER (PARTITION BY cs.cs_sold_date_sk ORDER BY (SUM(cs.cs_net_profit) - COALESCE(SUM(wr.wr_net_loss), 0)) / NULLIF(SUM(cs.cs_net_paid_inc_ship_tax) - COALESCE(SUM(wr.wr_return_amt_inc_tax), 0), 0) DESC) AS promo_rank
FROM
    catalog_sales cs
    LEFT JOIN web_returns wr
        ON cs.cs_order_number = wr.wr_order_number
        AND cs.cs_item_sk = wr.wr_item_sk
    JOIN (
        SELECT COUNT(*) AS total_stores
        FROM store
        WHERE s_state = 'CA'
    ) st
        ON TRUE
WHERE
    cs.cs_net_paid_inc_ship_tax > 500
    AND cs.cs_promo_sk IN (843, 587, 974)
    AND cs.cs_sold_date_sk BETWEEN 2450869 AND 2450914
GROUP BY
    cs.cs_promo_sk,
    cs.cs_sold_date_sk,
    st.total_stores
HAVING
    SUM(cs.cs_net_paid_inc_ship_tax) > 1000
ORDER BY
    cs.cs_sold_date_sk,
    profit_margin DESC
