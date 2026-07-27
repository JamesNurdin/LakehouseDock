WITH ss_agg AS (
    SELECT
        ss_hdemo_sk,
        ss_addr_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(ss_quantity) AS total_quantity
    FROM store_sales
    WHERE ss_list_price BETWEEN 20 AND 200
    GROUP BY ss_hdemo_sk, ss_addr_sk
),
joined AS (
    SELECT
        ca.ca_state,
        hd.hd_income_band_sk,
        ss_agg.total_sales,
        ss_agg.total_quantity,
        cr.cr_net_loss,
        ws.ws_net_profit,
        hd.hd_demo_sk
    FROM ss_agg
    JOIN household_demographics hd
        ON ss_agg.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
        ON ss_agg.ss_addr_sk = ca.ca_address_sk
    JOIN catalog_returns cr
        ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
       AND cr.cr_returning_addr_sk = ca.ca_address_sk
    JOIN web_sales ws
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
       AND ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE
        hd.hd_buy_potential = '>10000'
        AND ca.ca_location_type = 'single family'
        AND cr.cr_return_quantity > 1
        AND ws.ws_quantity > 2
        AND ss_agg.total_sales > 1000
        AND EXISTS (
            SELECT 1 FROM catalog_returns cr2
            WHERE cr2.cr_returning_hdemo_sk = hd.hd_demo_sk
              AND cr2.cr_return_amount > 50
        )
)
SELECT
    j.ca_state,
    COUNT(DISTINCT j.hd_income_band_sk) AS income_band_count,
    SUM(j.total_sales) AS state_total_sales,
    AVG(j.total_sales) AS avg_sales_per_demo,
    SUM(j.cr_net_loss) AS total_net_loss,
    AVG(j.ws_net_profit) AS avg_web_profit
FROM joined j
GROUP BY j.ca_state
HAVING SUM(j.total_sales) > 5000
ORDER BY state_total_sales DESC
