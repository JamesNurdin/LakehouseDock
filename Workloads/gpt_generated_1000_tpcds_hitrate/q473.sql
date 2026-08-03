WITH base AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_sold_date_sk,
        d.d_year,
        d.d_month_seq,
        i.i_item_sk,
        i.i_category,
        i.i_units,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        st.s_store_name,
        st.s_state,
        ca.ca_state,
        cd.cd_gender,
        cs.cs_net_profit,
        ss.ss_net_profit,
        ws.ws_net_profit,
        sr.sr_net_loss,
        inv.inv_quantity_on_hand,
        p.p_discount_active,
        (coalesce(cs.cs_net_profit, 0) +
         coalesce(ss.ss_net_profit, 0) +
         coalesce(ws.ws_net_profit, 0) -
         coalesce(sr.sr_net_loss, 0)) AS total_net_profit
    FROM store_sales ss
    JOIN date_dim d               ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store st                 ON ss.ss_store_sk = st.s_store_sk
    JOIN item i                  ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_address ca     ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib          ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN catalog_sales cs   ON cs.cs_item_sk = i.i_item_sk AND cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN web_sales ws       ON ws.ws_item_sk = i.i_item_sk AND ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN store_returns sr   ON sr.sr_item_sk = i.i_item_sk
                                 AND sr.sr_returned_date_sk = d.d_date_sk
                                 AND sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN inventory inv      ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d.d_date_sk
    LEFT JOIN promotion p        ON p.p_promo_sk = ss.ss_promo_sk
    WHERE d.d_year = 1998
      AND st.s_state = 'CA'
      AND i.i_units = 'Dozen'
      AND ib.ib_lower_bound > 50000
      AND EXISTS (
          SELECT 1
          FROM promotion p2
          WHERE p2.p_item_sk = i.i_item_sk
            AND p2.p_start_date_sk <= d.d_date_sk
            AND p2.p_end_date_sk   >= d.d_date_sk
      )
),
aggregated AS (
    SELECT
        b.s_store_name,
        b.d_year,
        b.d_month_seq,
        b.i_category,
        b.total_net_profit,
        CASE
            WHEN b.total_net_profit > (SELECT avg(total_net_profit) FROM base) THEN 'Above Avg'
            ELSE 'Below Avg'
        END AS profit_category,
        ROW_NUMBER() OVER (PARTITION BY b.d_year, b.d_month_seq ORDER BY b.total_net_profit DESC) AS rnk,
        LAG(b.total_net_profit) OVER (PARTITION BY b.s_store_name ORDER BY b.d_year, b.d_month_seq) AS prev_month_profit,
        SUM(b.total_net_profit) OVER (PARTITION BY b.s_store_name ORDER BY b.d_year, b.d_month_seq
                                      ROWS UNBOUNDED PRECEDING) AS running_profit
    FROM base b
)
SELECT
    s_store_name,
    d_year,
    d_month_seq,
    i_category,
    total_net_profit,
    profit_category,
    prev_month_profit,
    running_profit,
    rnk
FROM aggregated
WHERE rnk <= 3
ORDER BY d_year, d_month_seq, total_net_profit DESC
LIMIT 100
