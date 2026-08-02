WITH sales_aggregates AS (
    SELECT
        MIN(s.s_store_sk) AS store_sk,
        s.s_store_id,
        s.s_state,
        t.t_hour,
        t.t_am_pm,
        hd.hd_income_band_sk,
        ib.ib_upper_bound,
        r.r_reason_desc,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_catalog_orders,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_web_orders,
        SUM(cs.cs_net_paid) AS total_catalog_net_paid,
        SUM(ws.ws_net_paid) AS total_web_net_paid,
        SUM(sr.sr_net_loss) AS total_store_returns_loss,
        SUM(wr.wr_net_loss) AS total_web_returns_loss,
        -- profit category based on aggregated net paid and tax
        CASE 
            WHEN SUM(cs.cs_net_paid) - SUM(cs.cs_ext_tax) > 1000 THEN 'High'
            WHEN SUM(cs.cs_net_paid) - SUM(cs.cs_ext_tax) BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS catalog_profit_category,
        -- arrays of distinct order numbers for later unnesting
        array_agg(DISTINCT cs.cs_order_number) AS catalog_order_numbers,
        array_agg(DISTINCT ws.ws_order_number) AS web_order_numbers
    FROM
        store_returns sr
        JOIN store s ON sr.sr_store_sk = s.s_store_sk
        JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
        JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
        JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
        -- Catalog sales linked via the same time, customer, household and address dimensions
        JOIN catalog_sales cs ON cs.cs_sold_time_sk = t.t_time_sk
            AND cs.cs_bill_cdemo_sk = cd.cd_demo_sk
            AND cs.cs_bill_hdemo_sk = hd.hd_demo_sk
            AND cs.cs_bill_addr_sk = ca.ca_address_sk
        -- Web sales linked in the same way
        JOIN web_sales ws ON ws.ws_sold_time_sk = t.t_time_sk
            AND ws.ws_bill_cdemo_sk = cd.cd_demo_sk
            AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
            AND ws.ws_bill_addr_sk = ca.ca_address_sk
        -- Web returns linked to web sales, time and reason
        JOIN web_returns wr ON wr.wr_returned_time_sk = t.t_time_sk
            AND wr.wr_order_number = ws.ws_order_number
            AND wr.wr_item_sk = ws.ws_item_sk
            AND wr.wr_reason_sk = r.r_reason_sk
    WHERE
        t.t_am_pm = 'AM'
        AND t.t_minute BETWEEN 0 AND 15
        AND s.s_state = 'CA'
        AND r.r_reason_desc LIKE 'Did not %'
        AND ib.ib_upper_bound >= 90000
        AND cs.cs_quantity > 1
        AND ws.ws_quantity > 1
    GROUP BY
        ROLLUP (
            s.s_store_id,
            s.s_state,
            t.t_hour,
            t.t_am_pm,
            hd.hd_income_band_sk,
            ib.ib_upper_bound,
            r.r_reason_desc
        )
)
SELECT
    sa.store_sk,
    sa.s_store_id,
    sa.s_state,
    sa.t_hour,
    sa.t_am_pm,
    sa.hd_income_band_sk,
    sa.ib_upper_bound,
    sa.r_reason_desc,
    sa.catalog_profit_category,
    sa.distinct_catalog_orders,
    sa.distinct_web_orders,
    sa.total_catalog_net_paid,
    sa.total_web_net_paid,
    sa.total_store_returns_loss,
    sa.total_web_returns_loss,
    -- Correlated subquery: count of store returns for the same store that exceed the aggregated loss for the group
    (
        SELECT COUNT(*)
        FROM store_returns sr2
        WHERE sr2.sr_store_sk = sa.store_sk
          AND sr2.sr_net_loss > sa.total_store_returns_loss
    ) AS higher_store_return_loss_count,
    order_num
FROM
    sales_aggregates sa
    LEFT JOIN UNNEST(sa.catalog_order_numbers) AS t(order_num) ON TRUE
WHERE
    sa.total_catalog_net_paid > (
        SELECT AVG(total_catalog_net_paid)
        FROM sales_aggregates
    )
LIMIT 100
